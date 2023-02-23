// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract NFTSwap is IERC721Receiver {

  event List(address indexed seller, address indexed nftAddr, uint256 indexed tokenId, uint256 price);
  event Revoke(address indexed seller, address indexed nftAddr, uint256 indexed tokenId);
  event Update(address indexed seller, address indexed nftAddr, uint256 indexed tokenId, uint256 newPrice, uint256 oldPrice);
  event Purchase(address indexed buyer, address indexed nftAddr, uint256 indexed tokenId);

  error NOT_APPROVED();
  error NOT_OWNER();
  error INVALID_PRICE();
  error PRICE_NOT_CHANGED();
  error ORDER_NOT_EXIST();
  error INSUFFICIENT_VALUE();
  error TRANSFER_ETH_FAILED();

  struct Order {
    address owner;
    uint256 price;
  }

  // nftAddr => tokenId => order
  mapping(address => mapping(uint256 => Order)) public orders;

  function list(address nftAddr, uint256 tokenId, uint256 price) external {
    IERC721 nft = IERC721(nftAddr);
    if (nft.getApproved(tokenId) != address(this)) {
      revert NOT_APPROVED();
    }
//    if (nft.ownerOf(tokenId) != msg.sender) {
//      revert NOT_OWNER();
//    }
    if (price == 0) {
      revert INVALID_PRICE();
    }
    Order storage order = orders[nftAddr][tokenId];
    order.owner = msg.sender;
    order.price = price;
    nft.safeTransferFrom(msg.sender, address(this), tokenId);
    emit List(msg.sender, nftAddr, tokenId, price);
  }

  function revoke(address nftAddr, uint256 tokenId) external {
    Order storage order = orders[nftAddr][tokenId];
    if (msg.sender != order.owner) {
      revert NOT_OWNER();
    }
    order.owner = address(0);
    order.price = 0;
    IERC721(nftAddr).safeTransferFrom(address(this), msg.sender, tokenId);
    emit Revoke(msg.sender, nftAddr, tokenId);
  }

  function update(address nftAddr, uint256 tokenId, uint256 price) external {
    Order storage order = orders[nftAddr][tokenId];
    if (msg.sender != order.owner) {
      revert NOT_OWNER();
    }
    if (price == 0) {
      revert INVALID_PRICE();
    }
    if (price == order.price) {
      revert PRICE_NOT_CHANGED();
    }
    uint256 oldPrice = order.price;
    order.price = price;
    emit Update(msg.sender, nftAddr, tokenId, price, oldPrice);
  }

  function purchase(address nftAddr, uint256 tokenId) external payable {
    Order storage order = orders[nftAddr][tokenId];
    if (order.owner == address(0)) {
      revert ORDER_NOT_EXIST();
    }
    if (msg.value < order.price) {
      revert INSUFFICIENT_VALUE();
    }
    (bool success, ) = order.owner.call{value: order.price}("");
    if (!success) {
      revert TRANSFER_ETH_FAILED();
    }
    if (msg.value > order.price) {
      (bool success, ) = msg.sender.call{value: msg.value - order.price}("");
      if (!success) {
        revert TRANSFER_ETH_FAILED();
      }
    }
    order.owner = address(0);
    order.price = 0;
    IERC721(nftAddr).safeTransferFrom(address(this), msg.sender, tokenId);
    emit Purchase(msg.sender, nftAddr, tokenId);
  }

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }
}