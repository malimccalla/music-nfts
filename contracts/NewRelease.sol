// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

/// @custom:security-contact security@tunebase.com
contract Artist is ERC1155, AccessControl, Pausable, Ownable, ERC1155Supply {
    using Counters for Counters.Counter;

    address artistAddress;

    Counters.Counter public atReleaseId;
    Counters.Counter public atTokenId;

    // Mapping of release id to descriptive data.
    mapping(uint256 => Release) public releases;
    // Mapping of token id to edition id.
    mapping(uint256 => uint256) public tokenToRelease;

    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // IDS for the record certifications 
    uint256 public constant DIAMOND = 0;
    uint256 public constant PLATINUM = 1;
    uint256 public constant GOLD = 2;

    enum RecordCertificationLevel { GOLD, PLATINUM, DIAMOND }

    // To keep track of the amount of each token minted

    struct Release {
        string title;
        address artistAddress;
        uint256 maxDiamondSupply;
        uint256 maxPlatinumSupply;
        uint256 maxGoldSupply;
        uint256 maxTotalSupply;
        Counters.Counter mintedDiamondCount;
        Counters.Counter mintedPlatinumCount;
        Counters.Counter mintedGoldCount;
        uint256 diamondTokenId;
        uint256 platinumTokenId;
        uint256 goldTokenId;
        uint256 currentCertification;
    }

    function createRelease(string memory _title) public {
        releases[atReleaseId.current()] = Release(
            _title,
            artistAddress,
            10,
            30,
            60,
            100,
            0,
            0,
            0,
            atTokenId.current(),
            atTokenId.current() + 1,
            atTokenId.current() + 2,
            0
        );

        atReleaseId.increment();
    }

    constructor(address _artistAddress) ERC1155("https://tunebase.com/api/tokens/{id}") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        artistAddress = _artistAddress;

        // Set token id start to be 1 not 0
        atTokenId.increment();
        // Set release id start to be 1 not 0
        atReleaseId.increment();
    }

    function getReleasesById(uint tokenId) public view returns (ReleaseCertification[] memory) {
        return idToReleases[tokenId];
    }

    function getMintingPrice(uint _releaseId) public view returns (uint256) {
        return releases[_releaseId].mintPrice;
    }

    function buyRelease(uint memory _releaseId) public payable {
        if (releases[_releaseId].mintedDiamondCount.current() < releases[_releaseId].maxDiamondSupply) {
            _mint(msg.sender, releases[_releaseId].diamondTokenId, 1, "");
            releases[_releaseId].mintedDiamondCount.increment();
            // idToReleases[DIAMOND].push(ReleaseCertification(DIAMOND, payable(artistAddress), payable(msg.sender)));
            payable(artistAddress).transfer(msg.value);
        } else if (mintedPlatinumCount.current() < maxPlatinumSupply) {
            _mint(msg.sender, PLATINUM, 1, "");
            mintedPlatinumCount.increment();
            // idToReleases[PLATINUM].push(ReleaseCertification(PLATINUM, payable(artistAddress), payable(msg.sender)));
            payable(artistAddress).transfer(msg.value);
        } else if (mintedGoldCount.current() < maxGoldSupply) {
            _mint(msg.sender, GOLD, 1, "");
            mintedGoldCount.increment();
            // idToReleases[GOLD].push(ReleaseCertification(GOLD, payable(artistAddress), payable(msg.sender)));
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
