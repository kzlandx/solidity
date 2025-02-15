// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {BasicNFT} from "src/BasicNFT.sol";
import {SkullMemeNFT} from "src/SkullMemeNFT.sol";

contract MintBasicNFT is Script {
    address mostRecentDeployed;
    string public constant PUG = "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json";

    function run() public {
        mostRecentDeployed = DevOpsTools.get_most_recent_deployment("BasicNFT", block.chainid);
        mintNFTOnContract(mostRecentDeployed);
    }

    function mintNFTOnContract(address contractAddress) public {
        vm.startBroadcast();
        BasicNFT(contractAddress).mintNFT("PUG");
        vm.stopBroadcast();
    }
}

contract MintSkullMemeNFT is Script {
    address mostRecentDeployed;
    function run() public {
        mostRecentDeployed = DevOpsTools.get_most_recent_deployment("SkullMemeNFT", block.chainid);
        mintNFTOnContract(mostRecentDeployed);
    }

    function mintNFTOnContract(address contractAddress) public {
        vm.startBroadcast();
        SkullMemeNFT(contractAddress).mintNft();
        vm.stopBroadcast();
    }
}