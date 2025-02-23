// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {DeployMSC} from "../../script/DeployMSC.s.sol";
import {MSCEngine} from "../../src/MSCEngine.sol";
import {MSC} from "../../src/MSC.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/mocks/token/ERC20Mock.sol";

contract MSCEngineTest is Test {
    DeployMSC deployer;
    MSC msc;
    MSCEngine mscEngine;
    HelperConfig config;
    address weth;
    address ethUsdPriceFeed;

    address public USER = makeAddr("user");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;

    function setUp() public {
        deployer = new DeployMSC();
        (msc, mscEngine, config) = deployer.run();
        (ethUsdPriceFeed, , weth, , ) = config.activeNetworkConfig();

        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
    }

    /////////////////
    // Price Tests //
    /////////////////

    function testGetUsdValue() public view {
        // 10e18 * 3,000/ETH = 30,000e18
        uint256 ethAmount = 10e18;
        uint256 expectedUsd = 30000e18;
        uint256 actualUsd = mscEngine.getUSDValue(weth, ethAmount);
        assertEq(expectedUsd, actualUsd);
    }

    /////////////////////////////
    // depositCollateral Tests //
    /////////////////////////////

    function testRevertsIfCollateralZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(mscEngine), AMOUNT_COLLATERAL);

        vm.expectRevert(MSCEngine.MSCEngine__NeedsMoreThanZero.selector);
        mscEngine.depositCollateral(weth, 0);
        vm.stopPrank();
    }
}