// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MerkleAirdrop} from "src/MerkleAirdrop.sol";
import {BootToken} from "src/BootToken.sol";
import {Script} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployMerkleAirdrop is Script {
    bytes32 public s_merkleRoot = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 public s_amountToTransfer = 4 * 25 * 1e18;

    function run() external returns (BootToken, MerkleAirdrop) {
        return deployMerkleAirdrop();
    }

    function deployMerkleAirdrop() public returns (BootToken token, MerkleAirdrop airdrop) {
        vm.startBroadcast();
        token = new BootToken();
        airdrop = new MerkleAirdrop(s_merkleRoot, token);
        token.mint(token.owner(), s_amountToTransfer);
        token.transfer(address(airdrop), s_amountToTransfer);
        vm.stopBroadcast();
    }
}