// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {UUPSUpgradeable} from "@openzeppelin-upgradable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin-upgradable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin-upgradable/access/OwnableUpgradeable.sol";

// UUPS (Universal Upgrade Proxy Standard) Proxy
contract BoxV1 is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    uint256 internal num;

    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
    }

    function getNum() external view returns (uint256) {
        return num;
    }

    function version() external pure returns (uint256) {
        return 1;
    }

    function _authorizeUpgrade(address newImplementation) internal override {}
}