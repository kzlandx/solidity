// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";

contract ClaimAirdrop is Script {

    error __ClaimAirdropScript__InvalidSignatureLength();

    address private constant CLAIMING_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 public AMOUNT_TO_COLLECT = 25 * 1e18;
    bytes32 public proofOne = 0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
    bytes32 public proofTwo = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] public PROOF = [proofOne, proofTwo];
    bytes private signature = hex"257162602d6dd7656c5db14a32804e201ec2b9c8f8154deacf16acaa51db2013527ccb7145521cc486132d78c08db466d18116a5a4ce465303e2c5d37b2cf6cd1b";

    function claimAirdrop(address airdrop) public {
        vm.startBroadcast();
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);
        MerkleAirdrop(airdrop).claim(CLAIMING_ADDRESS, AMOUNT_TO_COLLECT, PROOF, v, r, s);
        vm.stopBroadcast();
    }

      function splitSignature(bytes memory sig) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        if (sig.length != 65) {
            revert __ClaimAirdropScript__InvalidSignatureLength();
        }
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("MerkleAirdrop", block.chainid);
        claimAirdrop(mostRecentlyDeployed);
    }
}

// 0x257162602d6dd7656c5db14a32804e201ec2b9c8f8154deacf16acaa51db2013527ccb7145521cc486132d78c08db466d18116a5a4ce465303e2c5d37b2cf6cd1b