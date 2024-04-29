// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFT is ERC721URIStorage {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address MarketplaceContract;
    event NFTMinted(uint256);

    constructor(address _marketplace) ERC721("FragToken", "FTKN") {
        MarketplaceContract = _marketplace;
    }

    function mint(string memory _tokenURI) public {
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, _tokenURI);
        setApprovalForAll(MarketplaceContract, true);
        _tokenIds.increment();

        emit NFTMinted(newItemId);
    }

    function getCurrentToken() public view returns(uint256) {
        return _tokenIds.current();
    }
}