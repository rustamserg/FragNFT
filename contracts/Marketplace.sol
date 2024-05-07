// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
 
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// "https://ipfs.io/ipfs/QmSHyHr3kHKza3YRMfNz5HFatotSvLSa17YHJPzXJow1gU",
// "https://ipfs.io/ipfs/QmVqKAMsQRbNcVffMUwyzVHhcx37sx46qnFX6nnYqu1rb9",
// "https://ipfs.io/ipfs/QmcEd1R1Qq7M6G7NnHxDXYdiYtJAn9A2FGjg94Ku75HgUD", 
// "https://ipfs.io/ipfs/QmUveY3PgfLD9TahrAEH2WieCG1PfU9Ybdq9WbZe8wXwvQ",
// "https://ipfs.io/ipfs/QmNeo34iQGsPLagnw1E6LjzfgmqVNLYftCymHKv11q9QsS",
// "https://ipfs.io/ipfs/QmXou1mty7AqhKzxrxC5C7Xqx8yVjVi8ZEqjacUpQQ89hD",

 
contract NFTMarketplace is ReentrancyGuard {
  using Counters for Counters.Counter;
  Counters.Counter private _nftsSold;
  Counters.Counter private _nftCount;
  uint256 public LISTING_FEE = 0.0001 ether;
  address payable private _marketOwner;
  mapping(uint256 => Token) private _idToToken;
 
  struct Token {
       address nftContract;
       uint256 tokenId;
       address payable seller;
       address payable owner;
       string tokenURI;
       string name;
       uint256 price;
       bool isListed;
   }
 
  event NFTListed(
    address nftContract,
    uint256 tokenId,
    address seller,
    address owner,
    uint256 price
  );
  
  event NFTSold(
    address nftContract,
    uint256 tokenId,
    address seller,
    address owner,
    uint256 price
  );
 
  constructor() {
    _marketOwner = payable(msg.sender);
  }
 
 
  // List the NFT on the marketplace
  function listNFT(address _nftContract, uint256 _tokenId, string memory _name, string memory _tokenURI) public payable nonReentrant {
    require(msg.value > 0, "Price must be at least 0.0001 ether");
    require(msg.value == LISTING_FEE, "Not enough ether for listing fee");

    IERC721(_nftContract).transferFrom(msg.sender, address(this), _tokenId);

    _nftCount.increment();

    _idToToken[_tokenId] = Token(
      _nftContract,
      _tokenId,
      payable(msg.sender),
      payable(address(this)),
      _tokenURI,
      _name,
      LISTING_FEE,
      true
    );

    emit NFTListed(_nftContract, _tokenId, payable(msg.sender), payable(address(this)), LISTING_FEE);
  }
 
  // Buy an NFT
  function buyNFT(address _nftContract, uint256 _tokenId) public payable nonReentrant  {
    Token storage nft = _idToToken[_tokenId];
    require(msg.value >= nft.price, "Not enough ether to cover token price");

    address owner = IERC721(_nftContract).ownerOf(_tokenId);
    address buyer = payable(msg.sender);
    
    payable(nft.seller).transfer(msg.value);
    
    IERC721(_nftContract).setApprovalForAll(buyer, true);
    IERC721(_nftContract).approve(buyer, nft.tokenId);
    IERC721(_nftContract).transferFrom(owner, buyer, nft.tokenId);

    _marketOwner.transfer(LISTING_FEE);
    nft.owner = payable(buyer);
    nft.isListed = false;

    _nftsSold.increment();
    emit NFTSold(_nftContract, nft.tokenId, nft.seller, buyer, msg.value);
  }
 
  // Resell an NFT purchased from the marketplace
  function resellNFT(address _nftContract, uint256 _tokenId) public payable nonReentrant {
    address owner = IERC721(_nftContract).ownerOf(_tokenId);
    Token storage nft = _idToToken[_tokenId];

    IERC721(_nftContract).transferFrom(owner, address(this), _tokenId);
    nft.seller = payable(msg.sender);
    nft.owner = payable(address(this));
    nft.isListed = true;

    _nftsSold.decrement();
    emit NFTListed(_nftContract, _tokenId, msg.sender, address(this), LISTING_FEE);
  }
}