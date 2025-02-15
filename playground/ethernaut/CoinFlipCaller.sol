// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICoinFlip {
    function flip(bool _guess) external returns (bool);
    function consecutiveWins() external view;
}

contract CoinFlipCaller {
    uint256 private constant FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    // ICoinFlip private coinFlip = ICoinFlip();

    function callTarget() public {
        
        // uint256 block_hash = uint256(blockhash(block.number - 1));
        // uint256 coin_flip = block_hash/FACTOR;
        // bool side = coin_flip == 1? true : false;

        // coinFlip.flip(side);
    }

    function getWins() public view {
        // coinFlip.consecutiveWins();
    }
}