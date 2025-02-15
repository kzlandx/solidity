// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {MyERC20} from "src/MyERC20.sol";
import {DeployMyERC20} from "script/DeployMyERC20.s.sol";

contract MyERC20Test is Test {
    MyERC20 public token;
    DeployMyERC20 public deployer;
    address kimy = makeAddr("Kimy");
    address timy = makeAddr("Timy");

    uint256 constant STARTING_BALANCE = 100 ether; // 100 Tokens

    function setUp() external {
        deployer = new DeployMyERC20();
        token = deployer.run();

        vm.prank(msg.sender); // default address
        token.transfer(kimy, STARTING_BALANCE);
    }

    function testKimyBalance() external view {
        assertEq(token.balanceOf(kimy), STARTING_BALANCE);
    }

    function testAllowances() external {
        uint256 initialAllowance = 1000;
        uint256 transferAmount = 500;

        // Kimy approves Timy to spend on her behalf
        vm.prank(kimy);
        token.approve(timy, initialAllowance);

        vm.prank(timy);
        token.transferFrom(kimy, timy, transferAmount);

        assertEq(token.balanceOf(kimy), STARTING_BALANCE - transferAmount);
        assertEq(token.balanceOf(timy), transferAmount);
    }
}