// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";

contract MyERC20 is ERC20 {
    constructor(uint256 _initialSupply) ERC20("KimiToken", "KIM") {
        _mint(msg.sender, _initialSupply);
    }
}