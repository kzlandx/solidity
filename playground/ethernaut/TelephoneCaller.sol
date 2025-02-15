// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITelephone {
    function changeOwner(address _owner) external;
    function owner() external returns (address);
}

contract TelephoneCaller {
    // ITelephone target = ITelephone();

    function callTarget() public {
        // target.changeOwner();
    }
}