// Invariants:
// 1. Total supply of MSC should be always less than the total value of collateral
// 2. Getter/view functions should never revert

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {DeployMSC} from "../../script/DeployMSC.s.sol";
import {MSCEngine} from "../../src/MSCEngine.sol";
import {MSC} from "../../src/MSC.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {Handler} from "./Handler.t.sol";
import {Test, console} from "forge-std/Test.sol";
// import {StdInvariant} from "forge-std/StdInvariant.sol"; // Test is already inheriting StdInvariant

contract OpenInvariantsTest is Test {
    DeployMSC deployer;
    MSCEngine mscEngine;
    MSC msc;
    HelperConfig config;
    Handler handler;
    address weth;
    address wbtc;

    function setUp() external {
        deployer = new DeployMSC();
        (msc, mscEngine, config) = deployer.run();
        
        handler = new Handler(msc, mscEngine);

        (,,weth, wbtc, ) = config.activeNetworkConfig();

        targetContract(address(handler));
    }

    function invariant_protocolMustHaveMoreValueThanTotalSupply() public view {
        uint256 totalSupply = msc.totalSupply();
        uint256 totalWethDeposited = IERC20(weth).balanceOf(address(mscEngine));
        uint256 totalWbtcDeposited = IERC20(wbtc).balanceOf(address(mscEngine));

        uint256 wethValue = mscEngine.getUSDValue(weth, totalWethDeposited);
        uint256 wbtcValue = mscEngine.getUSDValue(wbtc, totalWbtcDeposited);

        console.log("Weth Value: ", wethValue);
        console.log("Wbtc Value: ", wbtcValue);
        console.log("Total supply: ", totalSupply);

        assert(wethValue + wbtcValue >= totalSupply);
    }
}