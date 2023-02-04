// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DutchAuction is ERC721, Ownable {
  uint256 public constant MAX_SUPPLY = 10000;//总供应量
  uint256 public constant AUCTION_START_PRICE = 1 ether;//起拍价
  uint256 public constant AUCTION_END_PRICE = 0.1 ether;//地板价
  uint256 public constant AUCTION_TIME = 10 minutes;//拍卖总时长，为了方便测试，这里设置为10分钟
  uint256 public constant PRICE_DROP_INTERVAL = 1 minutes;//每隔多长时间，降价一次
  uint256 public constant PRICE_DROP_STEP = (AUCTION_START_PRICE - AUCTION_END_PRICE) / (AUCTION_TIME / PRICE_DROP_INTERVAL);//每次降价的金额

  uint256 public auctionStartTime;
  string private _baseTokenURI;
  uint256[] private _allTokens;

  constructor() ERC721("Dutch Auction", "DA") {
    auctionStartTime = block.timestamp;
  }

  function totalSupply() public view returns (uint256) {
    return _allTokens.length;
  }

  function auctionMint(uint256 quantity) external payable {
    require(block.timestamp >= auctionStartTime, "not started yet");
    require(totalSupply() + quantity <= MAX_SUPPLY, "exceed max supply");
    uint256 price = getAuctionPrice();
    require(msg.value >= price * quantity, "insufficient value");
    uint256 startTokenId = totalSupply();
    for (uint256 i = 0; i < quantity; ++i) {
      uint256 tokenId = startTokenId + i;
      _safeMint(msg.sender, tokenId);
      _allTokens.push(tokenId);
    }
    // 退回多余的金额
    if (msg.value > price * quantity) {
      (bool success,) = msg.sender.call{value : msg.value - price * quantity}("");
      require(success, "refund failed");
    }
  }

  function _baseURI() internal view override virtual returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string memory uri) external onlyOwner {
    _baseTokenURI = uri;
  }

  function getAuctionPrice() public view returns (uint256) {
    if (block.timestamp >= auctionStartTime + AUCTION_TIME) {
      return AUCTION_END_PRICE;
    } else if (block.timestamp <= auctionStartTime) {
      return AUCTION_START_PRICE;
    } else {
      uint256 steps = (block.timestamp - auctionStartTime) / PRICE_DROP_INTERVAL;
      return AUCTION_START_PRICE - PRICE_DROP_STEP * steps;
    }
  }

  function setAuctionStartTime(uint256 timestamp) external onlyOwner {
    auctionStartTime = timestamp;
  }

  function withdraw() external onlyOwner {
    (bool success,) = msg.sender.call{value : address(this).balance}("");
    require(success, "withdraw failed");
  }
}