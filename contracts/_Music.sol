//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ArtistFactory {
    Artist[] public deployedArtists;

    function createArtist() public {
        Artist newArtist = new Artist(msg.sender);
        deployedArtists.push(newArtist);
    }

    function getDeployedPolls() public view returns (Artist[] memory) {
        return deployedArtists;
    }
}

contract Artist is ReentrancyGuard {
  using Counters for Counters.Counter;
  Counters.Counter private _releaseIds;
  Counters.Counter private _releasesSold;

  Release[] public releases;
  address contractAddress;

  constructor(address artistAddress) {
    contractAddress = artistAddress;
  }

  function createRelease(
    uint price,
    uint goldSupply,
    uint platinumSupply,
    uint multiPlatinumSupply,
    uint diamondSupply
  ) public {
    Release newRelease = new Release(contractAddress, price, goldSupply, platinumSupply, multiPlatinumSupply, diamondSupply);
    releases.push(newRelease);
  }
}

contract Release is ERC1155 {
  // emum to identify the rarity level, this DOES NOT denote the supply of the rarity level
  uint256 public constant GOLD = 0;
  uint256 public constant PLATINUM = 1;
  uint256 public constant MULTI_PLATINUM = 2;
  uint256 public constant DIAMOND = 3;
  
  constructor(
    address fundingRecipient,
    uint price,
    uint goldSupply,
    uint platinumSupply,
    uint multiPlatinumSupply,
    uint diamondSupply
  ) ERC1155("https://api.music.com/metadata/{id}.json") {
    // this mints the tokens at creation but its also possible to add minting functionality to the contract to mint on demand to players.
    _mint(fundingRecipient, GOLD, goldSupply, "");
    _mint(fundingRecipient, PLATINUM, platinumSupply, "");
    _mint(fundingRecipient, MULTI_PLATINUM, multiPlatinumSupply, "");
    _mint(fundingRecipient, DIAMOND, diamondSupply, "");
  }
}