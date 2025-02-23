// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {MSC} from "../src/MSC.sol";
import {MSCEngine} from "../src/MSCEngine.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployMSC is Script {

    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function run() external returns (MSC, MSCEngine, HelperConfig) {
        HelperConfig config = new HelperConfig();

        (address wethUsdPriceFeed, address wbtcUsdPriceFeed, address weth, address wbtc,) = config.activeNetworkConfig(); // Omitting "uint256 deployerKey"

        tokenAddresses = [weth, wbtc];
        priceFeedAddresses = [wethUsdPriceFeed, wbtcUsdPriceFeed];

        vm.startBroadcast();
        MSC msc = new MSC(msg.sender);
        MSCEngine engine = new MSCEngine(tokenAddresses, priceFeedAddresses, address(msc));
        vm.stopBroadcast();

        vm.prank(msg.sender);
        msc.transferOwnership(address(engine));

        return (msc, engine, config);
    }
}