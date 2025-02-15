// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "lib/forge-std/src/Script.sol";
import {MockV3Aggregator} from "test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address priceFeed; // ETH/USD price feed address
    }

    NetworkConfig public activeNetworkConfig;

    // Magic numbers
    uint8 public constant DECIMAL = 8;
    int256 public constant INITIAL_PRICE = 3000e8;

    constructor () {
        if(block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        }
        else if(block.chainid == 300) {
            activeNetworkConfig = getZkSyncSepoliaEthConfig();
        }
        else if(block.chainid == 324) {
            activeNetworkConfig = getZkSyncEthConfig();
        }
        else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306 // ETH/USD Sepolia address
            });
        return sepoliaConfig;
    }

    function getZkSyncSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory zkSyncSepoliaConfig = NetworkConfig({
            priceFeed: 0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF // ETH/USD Zk-Sync Sepolia address
            });
        return zkSyncSepoliaConfig;
    }

    function getZkSyncEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory zkSyncConfig = NetworkConfig({
            priceFeed: 0x6D41d1dc818112880b40e26BD6FD347E41008eDA // ETH/USD Zk-Sync Mainnet address
            });
        return zkSyncConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMAL, INITIAL_PRICE);
        vm.stopBroadcast();
        
        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed)
            });
        return anvilConfig;
    }
}