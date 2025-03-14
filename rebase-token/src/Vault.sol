// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IRebaseToken} from "./interfaces/IRebaseToken.sol";

contract Vault {
    // We need to do the following things:
    // 1. Pass the token address to the constructor
    // 2. Create a deposit function that mints tokens to the user equal to the amount of ETH they deposit
    // 3. Create a redeem function that burns tokens from the user and sends ETH to the user
    // 4. Create a way to add rewards to the vault
    uint256 private constant MAX_BALANCE = type(uint256).max;

    IRebaseToken private immutable i_rebaseToken;

    event Deposit(address indexed user, uint256 amount);
    event Redeem(address indexed user, uint256 amount);

    error Vault__RedeemFailed();

    constructor(address _rebaseTokenAddress) {
        i_rebaseToken = IRebaseToken(_rebaseTokenAddress);
    }

    receive() external payable {}
    
    /**
     * @notice Allows users to deposit ETH into the vault and mint RBT tokens in return
     */
    function deposit() external payable {
        // We need to use the amount of ETH the user has sent to mint RBT tokens to the user
        i_rebaseToken.mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice Allows users to redeem their RBT tokens for ETH
     * @param _amount Amount of RBT tokens to redeem for ETH
     */
    function redeem(uint256 _amount) external {
        // Check if user wants to redeem their entire balance
        if (_amount == MAX_BALANCE) { // Doing this for mitigating against dust
            _amount = i_rebaseToken.balanceOf(msg.sender);
        }
        // Burn the RBT tokens from the user
        i_rebaseToken.burn(msg.sender, _amount);
        // Send ETH to the user
        (bool success,) = payable(msg.sender).call{value: _amount}("");
        if (!success) {
            revert Vault__RedeemFailed();
        }
        emit Redeem(msg.sender, _amount);
    }

    function getRebaseTokenAddress() external view returns (address) {
        return address(i_rebaseToken);
    }
}