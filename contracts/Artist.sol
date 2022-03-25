// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

/// @custom:security-contact security@tunebase.com
contract Artist is ERC1155, AccessControl, Pausable, Ownable, ERC1155Supply {
    using Counters for Counters.Counter;

    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    address artistAddress;
    string artistName;

    uint price = 0.02 ether;

    Counters.Counter public atReleaseId;
    Counters.Counter public atTokenId;

    // Mapping of release id to the release
    mapping(uint256 => Release) public releaseIdToReleases;
    // Mapping of the certification token ID to the release
    mapping(uint256 => ReleaseCertification) public tokenIdToReleaseCertifications;

    // IDS for the record certifications, in order of rarity
    uint256 public constant DIAMOND = 0;
    uint256 public constant PLATINUM = 1;
    uint256 public constant GOLD = 2;

    enum Certification { DIAMOND, PLATINUM, GOLD }

    struct ReleaseCertification {
        Certification certification;
        uint32 maxSupply;
        uint32 mintedCount;
        uint256 tokenId;
    }

    struct Release {
        address payable artistAddress;
        string title;
        uint32 maxTotalSupply;
        ReleaseCertification diamond;
        ReleaseCertification platinum;
        ReleaseCertification gold;
    }

    constructor(string memory _artistName, address _artistAddress) ERC1155("https://tunebase.com/api/tokens/{id}") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        artistAddress = _artistAddress;
        artistName = _artistName;

        // Set token id start to be 1 not 0
        atTokenId.increment();
        // Set release id start to be 1 not 0
        atReleaseId.increment();
    }

    function createRelease(string memory _title) public {
        require(msg.sender == artistAddress, "Only the artist can create a release");

        // Set the token IDs for each certification
        uint256 diamondTokenId = atTokenId.current(); 
        atTokenId.increment(); 
        uint256 platinumTokenId = atTokenId.current(); 
        atTokenId.increment(); 
        uint256 goldTokenId = atTokenId.current();

        ReleaseCertification memory diamondCert = ReleaseCertification(Certification.DIAMOND, 10, 0, diamondTokenId);
        ReleaseCertification memory platinumCert = ReleaseCertification(Certification.PLATINUM, 30, 0, platinumTokenId);
        ReleaseCertification memory goldCert = ReleaseCertification(Certification.GOLD, 60, 0, goldTokenId);

        releaseIdToReleases[atReleaseId.current()] = Release(
            payable(artistAddress),
            _title,
            100, // Max total supply across certifications
            diamondCert,
            platinumCert,
            goldCert
        );

        // Set a reference of token ID to release ID for diamond, platinum, and gold.
        tokenIdToReleaseCertifications[diamondTokenId] = diamondCert;
        tokenIdToReleaseCertifications[platinumTokenId] = platinumCert;
        tokenIdToReleaseCertifications[goldTokenId] = goldCert;

        // Increase IDs for the next release
        atReleaseId.increment();
        atTokenId.increment();
    }

    function getReleaseByReleaseId(uint _releaseId) public view returns (Release memory) {
        return releaseIdToReleases[_releaseId];
    }

    function getReleaseCertificationByTokenId(uint _tokenId) public view returns (ReleaseCertification memory) {
        return tokenIdToReleaseCertifications[_tokenId];
    }

    function buyRelease(uint _releaseId) public payable {
        require(releaseIdToReleases[_releaseId].maxTotalSupply > 0, "Release does not exist.");
        // require(releases[_releaseId].mintedTotalCount < releases[_releaseId].maxTotalSupply, "No tokens available to mint");
        require(msg.value >= price, "Must send enough to purchase the edition.");

        if (releaseIdToReleases[_releaseId].diamond.mintedCount < releaseIdToReleases[_releaseId].diamond.maxSupply) {
            _mint(msg.sender, releaseIdToReleases[_releaseId].diamond.tokenId, 1, "");
            releaseIdToReleases[_releaseId].diamond.mintedCount += 1;
            // idToReleases[DIAMOND].push(ReleaseCertification(DIAMOND, payable(artistAddress), payable(msg.sender)));
            payable(artistAddress).transfer(msg.value);
        } else if (releaseIdToReleases[_releaseId].platinum.mintedCount < releaseIdToReleases[_releaseId].platinum.maxSupply) {
            _mint(msg.sender, releaseIdToReleases[_releaseId].platinum.tokenId, 1, "");
            releaseIdToReleases[_releaseId].platinum.mintedCount += 1;
            // idToReleases[PLATINUM].push(ReleaseCertification(PLATINUM, payable(artistAddress), payable(msg.sender)));
            payable(artistAddress).transfer(msg.value);
        } else if (releaseIdToReleases[_releaseId].gold.mintedCount < releaseIdToReleases[_releaseId].gold.maxSupply) {
            _mint(msg.sender, releaseIdToReleases[_releaseId].gold.tokenId, 1, "");
            releaseIdToReleases[_releaseId].gold.mintedCount += 1;

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
