// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {UUPSUpgradeable} from "@openzeppelin-upgradable/proxy/utils/UUPSUpgradeable.sol";   

// UUPS (Universal Upgrade Proxy Standard) Proxy
contract BoxV2 is UUPSUpgradeable {
    uint256 internal num;

    function setNum(uint256 _num) external {
        num = _num;
    }

    function getNum() external view returns (uint256) {
        return num;
    }

    function version() external pure returns (uint256) {
        return 2;
    }

    function _authorizeUpgrade(address newImplementation) internal override {}
}