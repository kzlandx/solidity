// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/access/AccessControl.sol";

/**
 * @title RebaseToken
 * @author Kzlandx
 * @notice This is a rebase token that incentivizes users to deposit into a vault and gain interest in rewards
 * @notice The interest rate in the contract can only decrease
 * @notice Each user will have their own interest rate, i.e., the global interest rate at the time of depositing
 */
contract RebaseToken is ERC20, Ownable, AccessControl {

    ///////////////////////////////////////
    ///        STATE VARIABLES         ///
    /////////////////////////////////////
    // uint256 private s_interestRate = 5e10; // 0.000005 % per second
    uint256 private s_interestRate = (5 * PRECISION_FACTOR) / 1e8; // Why do this instead of above? To keep the interest rate we want regardless of the precision factor
    mapping (address => uint256) private s_userInterestRate;
    mapping (address => uint256) private s_userLastUpdatedTimestamp;

    uint256 private constant PRECISION_FACTOR = 1e18;
    uint256 private constant MAX_BALANCE = type(uint256).max; // Used to get the entire balance of user
    bytes32 private constant MINT_AND_BURN_ROLE = keccak256("MINT_AND_BURN_ROLE"); // creating a role


    ///////////////////////////////////////
    ///            EVENTS              ///
    /////////////////////////////////////
    event InterestRateSet(uint256 indexed newInterestRate);


    ///////////////////////////////////////
    ///            ERRORS              ///
    /////////////////////////////////////
    error RebaseToken__InterestRateCanOnlyDecrease();


    ///////////////////////////////////////
    ///          MODIFIERS             ///
    /////////////////////////////////////


    ///////////////////////////////////////
    ///          FUNCTIONS             ///
    /////////////////////////////////////
    constructor() ERC20("Rebase Token", "RBT") Ownable(msg.sender) {}

    /**
     * @notice Grants an account permission to mint and burn RBT tokens
     * @param _account The account to give permission to mint and burn RBT tokens
     */
    function grantMintAndBurnRole(address _account) external onlyOwner {
        _grantRole(MINT_AND_BURN_ROLE, _account);
    }

    /**
     * @notice Sets the interest rate in the contract
     * @param _newInterestRate The new interest rate to set
     * @dev The interest rate can only decrease
     */
    function setInterestRate(uint256 _newInterestRate) external onlyOwner {
        // Set the interest rate
        if (_newInterestRate > s_interestRate) {
            revert RebaseToken__InterestRateCanOnlyDecrease();
        }
        s_interestRate = _newInterestRate;
        emit InterestRateSet(_newInterestRate);
    }

    /**
     * @notice Mint the user RBT tokens when they deposit into the vault
     * @param _to The user to mint the RBT tokens to
     * @param _amount The amount of RBT tokens to mint
     */
    function mint(address _to, uint256 _amount) external onlyRole(MINT_AND_BURN_ROLE) {
        _mintAccruedInterest(_to);
        s_userInterestRate[_to] = s_interestRate;
        _mint(_to, _amount);
    }

    /**
     * @notice This function burns the required amount of RBT tokens of a user
     * @param _from The user of whose RBT tokens to burn 
     * @param _amount The amount of RBT tokens to burn
     */
    function burn(address _from, uint256 _amount) external onlyRole(MINT_AND_BURN_ROLE) {
        _mintAccruedInterest(_from);
        // if (_amount == MAX_BALANCE) { // Doing this for mitigating against dust
        //     _amount = balanceOf(_from);
        // }
        _burn(_from, _amount);
    }

    /**
     * @notice Transfer RBT tokens from one user to another
     * @param _recipient The user who is going to receive tokens
     * @param _amount The amount of tokens the recipient is going to receive
     * @return true if the transfer was successful
     */
    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        _mintAccruedInterest(msg.sender);
        _mintAccruedInterest(_recipient);
        if (_amount == MAX_BALANCE) { // Doing this for mitigating against dust
            _amount = balanceOf(msg.sender);
        }
        if (balanceOf(_recipient) == 0) {
            s_userInterestRate[_recipient] = s_userInterestRate[msg.sender];
        }
        return super.transfer(_recipient, _amount);
    }

    /**
     * @notice Transfer RBT tokens from one user to another
     * @param _sender The user who is going to send tokens
     * @param _recipient The user who is going to receive tokens
     * @param _amount The amount of tokens the recipient is going to receive
     * @return true if the transfer was successful
     */
    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        _mintAccruedInterest(msg.sender);
        _mintAccruedInterest(_recipient);
        if (_amount == MAX_BALANCE) { // Doing this for mitigating against dust
            _amount = balanceOf(msg.sender);
        }
        if (balanceOf(_recipient) == 0) {
            s_userInterestRate[_recipient] = s_userInterestRate[msg.sender];
        }
        return super.transferFrom(_sender, _recipient, _amount);
    }

    /**
     * @notice This function mints the accrued interest of a user since the last time they interacted with the protocol (mint, burn, transfer, etc.)
     * @param _user The user to whom to mint their accrued interest
     */
    function _mintAccruedInterest(address _user) internal {
        // (1) Find the current balance of RBT that have been minted to the user -> principal balance
        uint256 principalBalanceOfUser = super.balanceOf(_user);
        // (2) Calculate the user's current balance including any interest -> returned from balanceOf function
        uint256 currentBalanceOfUser = balanceOf(_user);
        // (3) Calculate the no. of tokens that need to be minted to the user -> (2) - (1)
        uint256 balanceIncrease = currentBalanceOfUser - principalBalanceOfUser;
        // Set the user's last updated timestamp to now
        s_userLastUpdatedTimestamp[_user] = block.timestamp;
        // Then call _mint to mint the required tokens to the user
        _mint(_user, balanceIncrease);
    }
    

    ///////////////////////////////////////
    ///         VIEW FUNCTIONS         ///
    /////////////////////////////////////
    /**
     * @notice This function will calculate the balance for a user including the interest that has been accumulated since the last update
     * Which is -> (principal balance) + interest that has accrued (accumulated)
     * @param _user The user of whose balance is to be calculated
     */
    function balanceOf(address _user) public view override returns (uint256) {
        // Get the current principal balance of the user (i.e., the no. of RBT that have actually been minted to the user)
        // Multiply the principal balance by the interest that has been accumulated in the time since the balance was last updated
        return (super.balanceOf(_user) * _calculateUserAccumulatedInterestSinceLastUpdate(_user)) / PRECISION_FACTOR; // (1e18 * 1e18) / 1e18 == 1e18
    }

    /**
     * @notice Returns the actual amount of tokens minted (excludes unminted accrued interest)
     * @param _user The user of whose principal balance to return
     */
    function principalBalanceOf(address _user) external view returns (uint256) {
        return super.balanceOf(_user);
    }

    /**
     * @notice This function calculates the interest that has been accumulated since the last update
     * @param _user The user of whose accumulated interest to calculate
     */
    function _calculateUserAccumulatedInterestSinceLastUpdate(address _user) internal view returns (uint256 linearInterest) {
        // Interest growth will be linear
        // 1. Calculate the time since last update
        // 2. Calculate the amount of linear growth
        // (principal amount) + (principal amount * user interest rate * time elapsed)
        // => (principle amount) * (1 + (user interest rate * time elapsed))
        // e.g., Deposit: 10 RBT
        // Interest rate: 0.0005 tokens per second
        // Time elapsed: 10 seconds
        // Calculated amount: (10) + (10 * 0.0005 * 10) == 10.05
        uint256 timeElapsed = block.timestamp - s_userLastUpdatedTimestamp[_user];
        linearInterest = PRECISION_FACTOR + (s_userInterestRate[_user] * timeElapsed);
    }

    /**
     * @notice Returns the global interest rate of the contract
     * @notice Any future depositors will receive this interest rate
     */
    function getInterestRate() external view returns (uint256) {
        return s_interestRate;
    }

    /**
     * @notice Returns the interest rate of a user
     * @param _user The user of whom the interest rate is to be returned
     */
    function getUserInterestRate(address _user) external view returns (uint256) {
        return s_userInterestRate[_user];
    }
}