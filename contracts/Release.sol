// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

/// @custom:security-contact security@tunebase.com
contract Release is ERC1155, AccessControl, Pausable, Ownable, ERC1155Supply {
    using Counters for Counters.Counter;
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // To keep track of the amount of each token minted
    Counters.Counter public mintedGoldCount;
    Counters.Counter public mintedPlatinumCount;
    Counters.Counter public mintedDiamondCount;

    uint256 public mintPrice = 0.02 ether;
    string public title;

    // Variables that get initialized on instantiation
    address public artistAddress;
    uint256 public maxGoldSupply;
    uint256 public maxPlatinumSupply;
    uint256 public maxDiamondSupply;
    uint256 public maxTotalSupply;

    // IDS for the record certifications 
    uint256 public constant DIAMOND = 0;
    uint256 public constant PLATINUM = 1;
    uint256 public constant GOLD = 2;

    struct ReleaseCertification {
      uint256 tokenId; // 0,1,2
      address payable artist;
      address payable owner;
    }

    mapping(uint256 => ReleaseCertification[]) private idToReleases;

    enum RecordCertificationLevel { GOLD, PLATINUM, DIAMOND }
    RecordCertificationLevel certification;
    RecordCertificationLevel constant defaultCertification = RecordCertificationLevel.DIAMOND;

    constructor(
        string memory _title
        // uint256 _maxGoldSupply,
        // uint256 _maxPlatinumSupply,
        // uint256 _maxDiamondSupply
    ) ERC1155("https://tunebase.com/api/tokens/{id}") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        artistAddress = msg.sender;
        title = _title;

        maxGoldSupply = 60; // _maxGoldSupply;
        maxPlatinumSupply = 30; // _maxPlatinumSupply;
        maxDiamondSupply = 10; // _maxDiamondSupply;
        maxTotalSupply = maxGoldSupply + maxPlatinumSupply + maxDiamondSupply;
    }

    function getReleasesById(uint tokenId) public view returns (ReleaseCertification[] memory) {
        return idToReleases[tokenId];
    }

    function getMintingPrice() public view returns (uint256) {
        return mintPrice;
    }

    function mint() public payable {
        require(msg.value == mintPrice, "Please submit the asking mint price in order to complete the purchase");

        if (mintedDiamondCount.current() < maxDiamondSupply) {
            _mint(msg.sender, DIAMOND, 1, "");
            mintedDiamondCount.increment();
            idToReleases[DIAMOND].push(ReleaseCertification(DIAMOND, payable(artistAddress), payable(msg.sender)));
            payable(artistAddress).transfer(msg.value);
        } else if (mintedPlatinumCount.current() < maxPlatinumSupply) {
            _mint(msg.sender, PLATINUM, 1, "");
            mintedPlatinumCount.increment();
            idToReleases[PLATINUM].push(ReleaseCertification(PLATINUM, payable(artistAddress), payable(msg.sender)));
            payable(artistAddress).transfer(msg.value);
        } else if (mintedGoldCount.current() < maxGoldSupply) {
            _mint(msg.sender, GOLD, 1, "");
            mintedGoldCount.increment();
            idToReleases[GOLD].push(ReleaseCertification(GOLD, payable(artistAddress), payable(msg.sender)));
            payable(artistAddress).transfer(msg.value);
        } else {
            revert("No tokens available to mint");
        }
    }

    // ====== NFT Functions ====== 

    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
