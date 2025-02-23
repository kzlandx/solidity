// SPDX-License-Identifier: MIT

// This is considered an Exogenous, Decentralized, Anchored (pegged), Crypto Collateralized low volatility coin

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity ^0.8.24;

import {MSC} from "./MSC.sol";
import {ReentrancyGuard} from "@openzeppelin/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title MSCEngine
 * @author kzlandx
 *
 * The system is designed to be as minimal as possible, and have the tokens maintain a 1 token == $1 peg at all times.
 * This is a stablecoin with the properties:
 * - Exogenously Collateralized
 * - USD Pegged
 * - Algorithmically Stable
 *
 * It is similar to DAI if DAI had no governance, no fees, and was backed by only WETH and WBTC.
 *
 * Our MSC system should always be "overcollateralized". At no point, should the value of
 * all collateral < the USD backed value of all the MSC.
 *
 * @notice This contract is the core of the MyStableCoin system. It handles all the logic
 * for minting and redeeming MSC, as well as depositing and withdrawing collateral.
 * @notice This contract is based on the MakerDAO DSS system
 */

contract MSCEngine is ReentrancyGuard {
    ///////////////////
    //     Errors    //
    ///////////////////

    error MSCEngine__NeedsMoreThanZero();
    error MSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
    error MSCEngine__TokenNotAllowed(address token);
    error MSCEngine__TransferFailed();
    error MSCEngine__BreaksHealthFactor(uint256 userHealthFactor);
    error MSCEngine__MintFailed();
    error MSCEngine__HealthFactorOk();
    error MSCEngine__HealthFactorNotImproved();

    /////////////////////////
    //   State Variables   //
    /////////////////////////

    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;
    mapping(address user => uint256 amountMSCMinted) private s_MSCMinted;
    address[] private s_collateralTokens;

    MSC private immutable i_MSC;

    uint256 private constant PRECISION = 1e18;
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant LIQUIDATION_THRESHOLD = 50;
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant LIQUIDATION_BONUS = 10; // 10% collateral bonus (when divided by LIQUIDATION_PRECISION (10/100 = 0.1))
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;

    ////////////////
    //   Events   //
    ////////////////

    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);
    event CollateralRedeemed(address indexed redeemedFrom, address indexed redeemedTo, address indexed token, uint256 amount);

    ///////////////////
    //   Modifiers   //
    ///////////////////

    modifier moreThanZero(uint256 amount) {
        if(amount <= 0) {
            revert MSCEngine__NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert MSCEngine__TokenNotAllowed(token);
        }
        _;
    }

    ///////////////////
    //   Functions   //
    ///////////////////

    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address MSCAddress) {
        if(tokenAddresses.length != priceFeedAddresses.length) {
            revert MSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
        }

        for(uint256 i=0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAddresses[i]);
        }

        i_MSC = MSC(MSCAddress);
    }


    ///////////////////////////
    //   External Functions  //
    ///////////////////////////

    /**
    * @param tokenCollateralAddress: the address of the token to deposit as collateral
    * @param amountCollateral: The amount of collateral to deposit
    * @param amountMscToMint: The amount of DecentralizedStableCoin to mint
    * This function will deposit your collateral and mint DSC in one transaction
    */
    function depositCollateralAndMintMSC(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountMscToMint) external {
        depositCollateral(tokenCollateralAddress, amountCollateral);
        mintMSC(amountMscToMint);
    }

    /**
     * @param tokenCollateralAddress: The ERC20 token address of the collateral you're depositing
     * @param amountCollateral: The amount of collateral you're depositing
     */
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral) public moreThanZero(amountCollateral) isAllowedToken(tokenCollateralAddress) nonReentrant {
        uint256 currentBalance = s_collateralDeposited[msg.sender][tokenCollateralAddress];

        if (currentBalance + amountCollateral < currentBalance) {
            revert MSCEngine__TransferFailed(); // Prevent overflow
        }
        
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);

        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if(!success){
            revert MSCEngine__TransferFailed();
        }
    }

    function redeemCollateralForMSC(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountMSCToBurn) external {
        burnMSC(amountMSCToBurn);
        redeemCollateral(tokenCollateralAddress, amountCollateral);
    }

    function redeemCollateral(address tokenCollateralAddress, uint256 amountCollateral) public moreThanZero(amountCollateral) nonReentrant {
         uint256 currentBalance = s_collateralDeposited[msg.sender][tokenCollateralAddress];

        if (amountCollateral > currentBalance) {
            revert MSCEngine__BreaksHealthFactor(_healthFactor(msg.sender)); // Prevent underflow
        }
        
        s_collateralDeposited[msg.sender][tokenCollateralAddress] -= amountCollateral;
        emit CollateralRedeemed(msg.sender, msg.sender, tokenCollateralAddress, amountCollateral);

        bool success = IERC20(tokenCollateralAddress).transfer(msg.sender, amountCollateral);
        if(!success){
            revert MSCEngine__TransferFailed();
        }

        _revertIfHealthFactorIsBroken(msg.sender);
    }

    /**
    * @param amountMSCToMint: The amount of MSC you want to mint
    * You can only mint MSC if you hav enough collateral
    */
    function mintMSC(uint256 amountMSCToMint) public moreThanZero(amountMSCToMint) nonReentrant {
        s_MSCMinted[msg.sender] += amountMSCToMint;
        _revertIfHealthFactorIsBroken(msg.sender);
        bool minted = i_MSC.mint(msg.sender, amountMSCToMint);

        if(!minted){
            revert MSCEngine__MintFailed();
        }
    }

    function burnMSC(uint256 amount) public moreThanZero(amount) {
        s_MSCMinted[msg.sender] -= amount;
        bool success = i_MSC.transferFrom(msg.sender, address(this), amount);
        if(!success){
            revert MSCEngine__TransferFailed();
        }

        i_MSC.burn(amount);
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    function _burnMSC(uint256 amountMSCToBurn, address onBehalfOf, address mscFrom) private moreThanZero(amountMSCToBurn){
        s_MSCMinted[onBehalfOf] -= amountMSCToBurn;
        bool success = i_MSC.transferFrom(mscFrom, address(this), amountMSCToBurn);
        if(!success) {
            revert MSCEngine__TransferFailed();
        }
        i_MSC.burn(amountMSCToBurn);
    }

    /**
    * @param collateral: The ERC20 token address of the collateral you're using to make the protocol solvent again.
    * This is collateral that you're going to take from the user who is insolvent.
    * In return, you have to burn your DSC to pay off their debt, but you don't pay off your own.
    * @param user: The user who is insolvent. They have to have a _healthFactor below MIN_HEALTH_FACTOR
    * @param debtToCover: The amount of MSC you want to burn to cover the user's debt.
    *
    * -> You can partially liquidate a user.
    * -> You will get a 10% LIQUIDATION_BONUS for taking the users funds.
    * -> This function working assumes that the protocol will be roughly 150% overcollateralized in order for this
    to work.
    * -> A known bug would be if the protocol was only 100% collateralized, we wouldn't be able to liquidate
    anyone.
    * -> For example, if the price of the collateral plummeted before anyone could be liquidated.
    */
    function liquidate(address collateral, address user, uint256 debtToCover) external moreThanZero(debtToCover) nonReentrant {
        uint256 startingUserHealthFactor = _healthFactor(user);
        if(startingUserHealthFactor > MIN_HEALTH_FACTOR){
            revert MSCEngine__HealthFactorOk();
        }

        uint256 tokenAmountFromDebtCovered = getTokenAmountFromUSD(collateral, debtToCover);

        uint256 bonusCollateral = (tokenAmountFromDebtCovered * LIQUIDATION_BONUS) / LIQUIDATION_PRECISION;

        uint256 totalCollateralRedeemed = tokenAmountFromDebtCovered + bonusCollateral;

        _redeemCollateral(collateral, totalCollateralRedeemed, user, msg.sender);
        _burnMSC(debtToCover, user, msg.sender);

        uint256 endingUserHealthFactor = _healthFactor(user);
        if(endingUserHealthFactor <= startingUserHealthFactor){
            revert MSCEngine__HealthFactorNotImproved();
        }

        _revertIfHealthFactorIsBroken(msg.sender);
    }

    function _redeemCollateral(address tokenCollateralAddress, uint256 amountCollateral, address from, address to) private {
        s_collateralDeposited[from][tokenCollateralAddress] -= amountCollateral;
        emit CollateralRedeemed(from, to, tokenCollateralAddress, amountCollateral);

        bool success = IERC20(tokenCollateralAddress).transfer(to, amountCollateral);
        if(!success){
            revert MSCEngine__TransferFailed();
        }
    }

    ///////////////////////////////////////////
    //   Private & Internal View Functions   //
    ///////////////////////////////////////////

    function _revertIfHealthFactorIsBroken(address user) internal view {
        uint256 userHealthFactor = _healthFactor(user);
        if(userHealthFactor < MIN_HEALTH_FACTOR){
            revert MSCEngine__BreaksHealthFactor(userHealthFactor);
        }
    }

    /**
    * Returns how close to liquidation a user is
    * If a user goes below 1, then they can be liquidated.
    */
    function _healthFactor(address user) private view returns (uint256) {
        (uint256 totalMSCMinted, uint256 collateralValueInUSD) = _getAccountInformation(user);

        return _calculateHealthFactor(totalMSCMinted, collateralValueInUSD);
    }

    function _getAccountInformation(address user) public view returns (uint256 totalMSCMinted,uint256 collateralValueInUSD) {
        totalMSCMinted = s_MSCMinted[user];
        collateralValueInUSD = getAccountCollateralValue(user);
    }

    function _calculateHealthFactor(
        uint256 totalMSCMinted,
        uint256 collateralValueInUsd
    )
        internal
        pure
        returns (uint256)
    {
        if (totalMSCMinted == 0) return type(uint256).max;
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        
        if (collateralAdjustedForThreshold > type(uint256).max / PRECISION) {
            return type(uint256).max; // Prevent overflow
        }
        
        return (collateralAdjustedForThreshold * PRECISION) / totalMSCMinted;
    }

    //////////////////////////////////////////
    //   Public & External View Functions   //
    //////////////////////////////////////////

    function getAccountCollateralValue(address user) public view returns (uint256 totalCollateralValueInUSD) {
        for(uint256 i = 0; i < s_collateralTokens.length; i++){
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUSD += getUSDValue(token, amount);
        }
    }

    function getUSDValue(address token, uint256 amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (,int256 price,,,) = priceFeed.latestRoundData();

        return ((uint256(price) * ADDITIONAL_FEED_PRECISION) * amount) / PRECISION;
    }

    function getTokenAmountFromUSD(address token, uint256 usdAmountInWei) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData();

        return (usdAmountInWei * PRECISION) / (uint256(price) * ADDITIONAL_FEED_PRECISION);
    }

    function getPrecision() external pure returns (uint256) {
        return PRECISION;
    }

    function getAdditionalFeedPrecision() external pure returns (uint256) {
        return ADDITIONAL_FEED_PRECISION;
    }

    function getLiquidationThreshold() external pure returns (uint256) {
        return LIQUIDATION_THRESHOLD;
    }

    function getLiquidationBonus() external pure returns (uint256) {
        return LIQUIDATION_BONUS;
    }

    function getLiquidationPrecision() external pure returns (uint256) {
        return LIQUIDATION_PRECISION;
    }

    function getMinHealthFactor() external pure returns (uint256) {
        return MIN_HEALTH_FACTOR;
    }

    function getCollateralTokens() external view returns (address[] memory) {
        return s_collateralTokens;
    }

    function getMSC() external view returns (address) {
        return address(i_MSC);
    }

    function getCollateralTokenPriceFeed(address token) external view returns (address) {
        return s_priceFeeds[token];
    }

    function getHealthFactor(address user) external view returns (uint256) {
        return _healthFactor(user);
    }

    function getCollateralBalanceOfUser(address user, address collateral) external view returns (uint256) {
        return s_collateralDeposited[user][collateral];
    }
}