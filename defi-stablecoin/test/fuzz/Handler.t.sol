// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MSCEngine} from "../../src/MSCEngine.sol";
import {MSC} from "../../src/MSC.sol";
import {Test} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/mocks/token/ERC20Mock.sol";

contract Handler is Test {
    MSCEngine mscEngine;
    MSC msc;

    ERC20Mock weth;
    ERC20Mock wbtc;

    uint256 MAX_DEPOSIT_SIZE = type(uint96).max;

    constructor(MSC _msc, MSCEngine _engine) {
        msc = _msc;
        mscEngine = _engine;

        address[] memory collateralTokens = mscEngine.getCollateralTokens();
        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);
    }

    function setUp() external {}

    function depositCollateral(uint256 collateralSeed, uint256 amountCollateral) public {
        amountCollateral = bound(amountCollateral, 1, MAX_DEPOSIT_SIZE);
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);

        // mint and approve!
        vm.startPrank(msg.sender);
        collateral.mint(msg.sender, amountCollateral);
        collateral.approve(address(mscEngine), amountCollateral);

        mscEngine.depositCollateral(address(collateral), amountCollateral);
    }

    function redeemCollateral(uint256 collateralSeed, uint256 amountCollateral) public {
        depositCollateral(collateralSeed, amountCollateral);
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        uint256 maxCollateralToRedeem = mscEngine.getCollateralBalanceOfUser(msg.sender, address(collateral));

        amountCollateral = bound(amountCollateral, 1, maxCollateralToRedeem);

        if(amountCollateral == 0){
            return;
        }

        mscEngine.redeemCollateral(address(collateral), amountCollateral);
    }

    // May be broken
    function mintDsc(uint256 amount) public {
        (uint256 totalMSCMinted, uint256 collateralValueInUsd) = mscEngine._getAccountInformation(msg.sender);

        int256 maxMSCToMint = (int256(collateralValueInUsd) / 2) - int256(totalMSCMinted);
        if(maxMSCToMint < 0){
            return;
        }
        amount = bound(amount, 0, uint256(maxMSCToMint));
        if (amount == 0){
            return;
        }

        vm.startPrank(msg.sender);
        mscEngine.mintMSC(amount);
        vm.stopPrank();
    }

    // Helper functions
    function _getCollateralFromSeed(uint256 collateralSeed) private view returns (ERC20Mock){
        if(collateralSeed % 2 == 0){
            return weth;
        }
        return wbtc;
    }
}