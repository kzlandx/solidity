// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/access/Ownable.sol";

contract Box is Ownable {

    uint256 num;

    event NumChanged(uint256 newNum);

    constructor() Ownable(msg.sender) {}

    function setNum(uint256 newNum) public onlyOwner {
        num = newNum;
        emit NumChanged(newNum);
    }

    function getNum() external view returns (uint256) {
        return num;
    }
}