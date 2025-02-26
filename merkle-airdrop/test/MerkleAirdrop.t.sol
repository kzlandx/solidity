// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {BootToken} from "src/BootToken.sol";
import {MerkleAirdrop} from "src/MerkleAirdrop.sol";
import {DeployMerkleAirdrop} from "script/DeployMerkleAirdrop.s.sol";
import {ZkSyncChainChecker} from "@foundry-devops/ZkSyncChainChecker.sol";

contract MerkleAirdropTest is Test, ZkSyncChainChecker {
    BootToken public token;
    MerkleAirdrop public airdrop;

    bytes32 public ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 public AMOUNT_TO_CLAIM = 25 * 1e18;
    uint256 public AMOUNT_TO_SEND = 4 * AMOUNT_TO_CLAIM;
    bytes32 public proofOne = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 public proofTwo = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] public PROOF = [proofOne, proofTwo];

    address user;
    address gasPayer;
    uint256 userPrivKey;

    function setUp() public {
        if (!isZkSyncChain()) {
            DeployMerkleAirdrop deployer = new DeployMerkleAirdrop();
            (token, airdrop) = deployer.run();
        }
        else {
            token = new BootToken();
            airdrop = new MerkleAirdrop(ROOT, token);
            token.mint(address(this), AMOUNT_TO_SEND);
            token.transfer(address(airdrop), AMOUNT_TO_SEND);
        }

        (user, userPrivKey) = makeAddrAndKey("user");
        gasPayer = makeAddr("gasPayer");
    }

    function testUsersCanClaim() public {
        vm.prank(user);
        (uint8 v, bytes32 r, bytes32 s) = signMessage(userPrivKey, user);

        uint256 startingBalance = token.balanceOf(user);
        console.log("Starting balance: ", startingBalance);

        vm.prank(gasPayer);
        airdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);

        uint256 endingBalance = token.balanceOf(user);
        console.log("Ending balance: ", endingBalance);

        assertEq(endingBalance - startingBalance, AMOUNT_TO_CLAIM);
    }

    function signMessage(uint256 privKey, address account) public view returns (uint8 v, bytes32 r, bytes32 s) {
        bytes32 hashedMessage = airdrop.getMessageHash(account, AMOUNT_TO_CLAIM);
        (v, r, s) = vm.sign(privKey, hashedMessage);
    }
}