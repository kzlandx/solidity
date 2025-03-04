// SPDX-License-Identifier: MIT

// This is considered an Exogenous, Decentralized, Anchored (pegged), Crypto Collateralized low volatility coin

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity ^0.8.24;

import {ERC20Burnable, ERC20} from "@openzeppelin/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";

/*
 * @title: MyStableCoin
 * @author: kzlandx
 * Collateral: Exogenous (ETH & BTC)
 * Minting: Algorithmic
 * Relative Stability: Pegged to USD
 *
 * This is the contract meant to be governed by MSCEngine. This contract is just the ERC20 implementation of our stablecoin system.
 */
contract MSC is ERC20Burnable, Ownable {

    // ERRORS
    error MSC__MustBeMoreThanZero();
    error MSC__BurnAmountExceedsBalance();
    error MSC__NotZeroAddress();

    // CONSTRUCTOR
    constructor(address initialOwner) ERC20("MyStableCoin", "MSC") Ownable(initialOwner) {}

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if(_amount <= 0) {
            revert MSC__MustBeMoreThanZero();
        }
        if(balance < _amount) {
            revert MSC__BurnAmountExceedsBalance();
        }
        super.burn(_amount);
    }

    function mint(address _to, uint256 _amount) external onlyOwner returns(bool) {
        if(_to == address(0)) {
            revert MSC__NotZeroAddress();
        }
        if(_amount <= 0) {
            revert MSC__MustBeMoreThanZero();
        }
        _mint(_to, _amount);
        return true;
    }
}