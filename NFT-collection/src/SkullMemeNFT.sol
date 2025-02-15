// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/token/ERC721/ERC721.sol";
import {Base64} from "@openzeppelin/utils/Base64.sol";

contract SkullMemeNFT is ERC721 {
    string private s_berserkSvgImageUri;
    string private s_minecraftSvgImageUri;
    string private s_aotSvgImageUri;
    uint256 private s_tokenCounter;

    mapping(uint256 => string) private s_tokenIdToUri;

    enum CurrentSkull {
        BERSERK,
        MINECRAFT,
        AOT
    }

    mapping(uint256 => CurrentSkull) private s_tokenIdToCurrentSkull;

    constructor(string memory berserkSvgImageUri, string memory minecraftSvgImageUri, string memory aotSvgImageUri) ERC721("Skully", "SKULLS") {
        s_tokenCounter = 0;
        s_berserkSvgImageUri = berserkSvgImageUri;
        s_minecraftSvgImageUri = minecraftSvgImageUri;
        s_aotSvgImageUri = aotSvgImageUri;
    }

    function mintNft() public {
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenIdToCurrentSkull[s_tokenCounter] = CurrentSkull.BERSERK;
        s_tokenCounter++;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory){
        string memory imageURI;
        if (s_tokenIdToCurrentSkull[tokenId] == CurrentSkull.BERSERK) {
            imageURI = s_berserkSvgImageUri;
        }
        else if (s_tokenIdToCurrentSkull[tokenId] == CurrentSkull.MINECRAFT) {
            imageURI = s_minecraftSvgImageUri;
        }
        else {
            imageURI = s_aotSvgImageUri;
        }

        string memory tokenMetadata = Base64.encode(abi.encodePacked(
            "data:application/json;base64,",
            '{"name: "',
            name(),
            '", description: "Berserk skull meme NFT!", "attributes": [{"trait_type": "CurrentSkull", "value": 100}], "image": ',
            imageURI,
            '"}'
        ));
        return tokenMetadata;
    }

    function approveUser(address _user, uint256 tokenId) public {
        approve(_user, tokenId);
    }

    function flipCurrentSkull(uint256 tokenId) public {
        address tokenOwner = ownerOf(tokenId);
        _checkAuthorized(tokenOwner, msg.sender, tokenId);

        if(s_tokenIdToCurrentSkull[tokenId] == CurrentSkull.BERSERK) {
            s_tokenIdToCurrentSkull[tokenId] = CurrentSkull.MINECRAFT;
        } 
        else if (s_tokenIdToCurrentSkull[tokenId] == CurrentSkull.MINECRAFT) {
            s_tokenIdToCurrentSkull[tokenId] = CurrentSkull.AOT;
        }
        else {
            s_tokenIdToCurrentSkull[tokenId] = CurrentSkull.BERSERK;
        }
    }
    

    function getCurrentSkull(uint256 tokenId) public view returns (CurrentSkull) {
        return s_tokenIdToCurrentSkull[tokenId];
    }
}