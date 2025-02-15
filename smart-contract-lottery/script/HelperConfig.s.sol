// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

abstract contract CodeConstants {
    // VRF MOCK VALUES
    uint96 constant MOCK_BASE_FEE = 0.25 ether;
    uint96 constant MOCK_GAS_PRICE_LINK = 1e9;
    int256 constant MOCK_WEI_PER_UNIT_LINK = 4e15;

    uint256 constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 constant LOCAL_CHAIN_ID = 31337;
    uint256 constant SEPOLIA_OP_CHAIN_ID = 11155420;
}

contract HelperConfig is Script, CodeConstants {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        uint256 entranceFee; 
        uint256 interval;
        address vrfCoordinator; 
        bytes32 gasLane;
        uint32 callbackGasLimit;
        uint256 subscriptionId;
        address link;
        address account;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[SEPOLIA_CHAIN_ID] = getSepoliaETHConfig();
        networkConfigs[SEPOLIA_OP_CHAIN_ID] = getSepoliaOpETHConfig();
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        }
        else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilETHConfig();
        }
        else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getSepoliaETHConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit: 500000,
            subscriptionId: 71867926214755076678426255454059055489262185799131533806730649807873917270340,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            account: 0xBbcE97f8BFCaB8503b4f9e06C4ae630EB244c8D2
        });
    }

    function getSepoliaOpETHConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({ // LINK TOKEN address: 0xE4aB69C077896252FAFBD49EFD26B5D171A32410
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: 0x02667f44a6a44E4BDddCF80e724512Ad3426B17d,
            gasLane: 0xc3d5bc4d5600fa71f7a50b9ad841f14f24f9ca4236fd00bdb5fda56b052b28a4,
            callbackGasLimit: 500000,
            subscriptionId: 0, // not set
            link: 0xE4aB69C077896252FAFBD49EFD26B5D171A32410,
            account: 0xBbcE97f8BFCaB8503b4f9e06C4ae630EB244c8D2
        });
    }

    function getOrCreateAnvilETHConfig() public returns (NetworkConfig memory) {
        // check if there is any active network config
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }

        // deploy mock contract
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK, MOCK_WEI_PER_UNIT_LINK);
        LinkToken linkToken = new LinkToken();
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: address(vrfCoordinatorMock),
            gasLane: 0xc3d5bc4d5600fa71f7a50b9ad841f14f24f9ca4236fd00bdb5fda56b052b28a4, // doesn't matter
            callbackGasLimit: 500000,
            subscriptionId: 0, // We will create it ourselves
            link: address(linkToken),
            account: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38 // Foundry default address, from Base.sol
        });

        return localNetworkConfig;
    }
}