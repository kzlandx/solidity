// SPDX-License-Identifier:MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {SkullMemeNFT} from "src/SkullMemeNFT.sol";
import {Base64} from "@openzeppelin/utils/Base64.sol";

contract DeploySkullMemeNFT is Script {
    function run() external returns (SkullMemeNFT) {
        string memory skullBerserkSvg = vm.readFile("./img/skullBerserk.svg");
        string memory skullMinecraftSvg = vm.readFile("./img/skullMinecraft.svg");
        string memory skullAotSvg = vm.readFile("./img/skullAot.svg");

        vm.startBroadcast();
        SkullMemeNFT skullMemeNFT = new SkullMemeNFT(svgToImageURI(skullBerserkSvg), svgToImageURI(skullMinecraftSvg), svgToImageURI(skullAotSvg));
        vm.stopBroadcast();

        return skullMemeNFT;
    }

    function svgToImageURI(string memory svg) public pure returns (string memory) {
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(bytes(svg));

        return string.concat(baseURL, svgBase64Encoded);
    }
}