// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {RebaseToken} from "../src/RebaseToken.sol";
import {Vault} from "../src/Vault.sol";

contract RebaseTokenTest is Test {
    RebaseToken private rbt;
    Vault private vault;

    address private owner = makeAddr("owner");
    address private user1 = makeAddr("user1");
    address private user2 = makeAddr("user2");

    uint256 private constant MAX_BALANCE = type(uint256).max;
    uint256 private constant CURRENT_INTEREST_RATE = 5e10; // 0.00000005 %
    // uint256 private constant STARTING_BALANCE = 10e18; // 10 ETH
    // uint256 private constant DEPOSIT_AMOUNT = 5e18; // 5 ETH

    function setUp() public {
        vm.startPrank(owner);
        rbt = new RebaseToken();
        vault = new Vault(address(rbt));
        rbt.grantMintAndBurnRole(address(vault));
        // vm.deal(address(vault), 10 ether);
        vm.stopPrank();
        // vm.deal(user1, STARTING_BALANCE);
    }

    ///////////////////////////////////////
    ///          UNIT TESTS            ///
    /////////////////////////////////////
    function testNonOwnerCannotSetInterestRate(uint256 newInterestRate) public {
        newInterestRate = bound(newInterestRate, 1, CURRENT_INTEREST_RATE);
        vm.prank(user1);
        vm.expectRevert();
        rbt.setInterestRate(newInterestRate);
    }

    function testOwnerCanSetInterestRate(uint256 newInterestRate) public {
        newInterestRate = bound(newInterestRate, 1, CURRENT_INTEREST_RATE);
        vm.prank(owner);
        rbt.setInterestRate(newInterestRate);
    }


    ///////////////////////////////////////
    ///       INTEGRATION TESTS        ///
    /////////////////////////////////////
    function testInterestIsLinear(uint256 amount) public {
        // Bounding the amount to be between 1,00,000 wei and (2^96 - 1) wei
        amount = bound(amount, 1e5, type(uint96).max);
        // 1. user1 deposits some ETH to the vault
        vm.deal(user1, amount);
        vm.prank(user1);
        vault.deposit{value: amount}();
        // 2. Check RBT token balance of user1
        uint256 startBalance = rbt.balanceOf(user1);
        console.log("Start balance: ", startBalance);
        assertEq(startBalance, amount);
        // 3. Warp time and check balance again
        vm.warp(block.timestamp + 1 hours);
        uint256 middleBalance = rbt.balanceOf(user1);
        console.log("Middle balance: ", middleBalance);
        assertGt(middleBalance, startBalance);
        // 4. Warp time again by same amount and check balance
        vm.warp(block.timestamp + 1 hours);
        uint256 endBalance = rbt.balanceOf(user1);
        console.log("End balance: ", endBalance);
        assertGt(endBalance, middleBalance);

        // assertEq(endBalance - middleBalance, middleBalance - startBalance); // fails due to truncation
        assertApproxEqAbs(endBalance - middleBalance, middleBalance - startBalance, 1);
    }

    function testRedeemStraightAway(uint256 amount) public {
        amount = bound(amount, 1e5, type(uint96).max);
        vm.deal(user1, amount);
        vm.startPrank(user1);
        vault.deposit{value: amount}();
        assertEq(rbt.balanceOf(user1), amount);
        vault.redeem(MAX_BALANCE);
        assertEq(rbt.balanceOf(user1), 0);
        assertEq(address(user1).balance, amount);
        vm.stopPrank();
    }

    function testRedeemAfterSomeTimeHasPassed(uint256 depositAmount, uint256 time) public {
        depositAmount = bound(depositAmount, 1e5, type(uint96).max);
        time = bound(time, 1000, type(uint96).max);
        vm.deal(user1, depositAmount);
        vm.startPrank(user1);
        vault.deposit{value: depositAmount}();
        vm.warp(block.timestamp + time);
        uint256 rbtBalance = rbt.balanceOf(user1);
        addRewardsToVault(rbtBalance - depositAmount);
        vault.redeem(MAX_BALANCE);
        vm.stopPrank();
        uint256 ethBalance = address(user1).balance;
        assertEq(rbt.balanceOf(user1), 0);
        assertEq(ethBalance, rbtBalance);
        assertGt(ethBalance, depositAmount);
    }

    function testTransfer(uint256 depositAmount, uint256 amountToSend) public {
        depositAmount = bound(depositAmount, 1e5, type(uint96).max);
        amountToSend = bound(amountToSend, 1e5, depositAmount);
        console.log("Deposit amount: ", depositAmount);
        console.log("Amount to send: ", amountToSend);
        // 1. Deposit
        vm.deal(user1, depositAmount);
        vm.startPrank(user1);
        vault.deposit{value: depositAmount}();
        assertEq(rbt.getUserInterestRate(user1), rbt.getInterestRate());
        assertEq(rbt.getUserInterestRate(user2), 0);
        // 2. Transfer
        rbt.transfer(user2, amountToSend);
        vm.stopPrank();
        // 3. Asserts
        assertEq(rbt.balanceOf(user1), depositAmount - amountToSend);
        assertEq(rbt.balanceOf(user2), amountToSend);
        assertEq(rbt.getUserInterestRate(user2), rbt.getInterestRate());
    }


    ///////////////////////////////////////
    ///       HELPER FUNCTIONS         ///
    /////////////////////////////////////
    function addRewardsToVault(uint256 rewardAmount) public {
        vm.deal(address(vault), address(vault).balance + rewardAmount);
    }
}