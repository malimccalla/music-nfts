// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Artist.sol";

contract ArtistFactory is AccessControl, Pausable, Ownable {
    using Counters for Counters.Counter;

    // ============ Storage ============
    Counters.Counter public artistsCount;
    address public admin;
    address public artistAddress;
    address public artistId;
    // registry of created artists
    Artist[] public deployedArtists;

    // Initializes factory
    constructor() {
      // Set admin to whoever deployed the contract
      admin = msg.sender;
    }

    // Creates a new release contract
    function createArtist(string memory _artistName, address _artistAddress) public {
        require(msg.sender == admin, "Not authoried to create artists.");
        // add to registry

        deployedArtists.push(new Artist(
            _artistName,
            _artistAddress
        ));

        artistsCount.increment();
    }

    /// Sets the admin for authorizing artist deployment
    /// @param _newAdmin address of new admin
    function setAdmin(address _newAdmin) external {
        require(msg.sender == admin, 'invalid authorization');
        admin = _newAdmin;
    }
}