// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {DeploySkullMemeNFT} from "script/DeploySkullMemeNFT.s.sol";
import {Test} from "forge-std/Test.sol";

contract DeployMoodNftTest is Test {
    DeploySkullMemeNFT public deployer;
    
    function setUp() public {
        deployer = new DeploySkullMemeNFT();
    }

    function testConvertSvgToUri() public view {
        string memory expectedUri = "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48Y2lyY2xlIGN4PSI1MCIgY3k9IjUwIiByPSI0MCIgZmlsbD0icmVkIiAvPjwvc3ZnPg==";
        string memory svg = '<svg width="100" height="100" xmlns="http://www.w3.org/2000/svg"><circle cx="50" cy="50" r="40" fill="red" /></svg>';

        string memory actualUri = deployer.svgToImageURI(svg);
        
        assert(keccak256(bytes(expectedUri)) == keccak256(bytes(actualUri)));
    }
}