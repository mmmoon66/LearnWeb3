// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {NFTSwap} from "../A38_NFTSwap.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TestNFT is ERC721 {

  error NOT_OWNER();

  address immutable public owner;

  constructor() ERC721("Test NFT", "TEST") {
    owner = msg.sender;
  }

  function mint(address to, uint256 tokenId) external {
    if (msg.sender != owner) revert NOT_OWNER();
    ERC721._safeMint(to, tokenId);
  }
}

contract NFTSwap_Test is Test {

  event List(address indexed seller, address indexed nftAddr, uint256 indexed tokenId, uint256 price);
  event Revoke(address indexed seller, address indexed nftAddr, uint256 indexed tokenId);
  event Update(address indexed seller, address indexed nftAddr, uint256 indexed tokenId, uint256 newPrice, uint256 oldPrice);
  event Purchase(address indexed buyer, address indexed nftAddr, uint256 indexed tokenId);

  NFTSwap public nftSwap;
  TestNFT public testNFT;

  function setUp() public {
    nftSwap = new NFTSwap();
    testNFT = new TestNFT();
  }

  function testList() public {
    address alice = vm.addr(1);
    uint256 tokenId = 666;
    testNFT.mint(alice, tokenId);

    // test revert NOT_APPROVED
    vm.expectRevert(NFTSwap.NOT_APPROVED.selector);
    nftSwap.list(address(testNFT), tokenId, 1 ether);

    vm.startPrank(alice);
    testNFT.approve(address(nftSwap), tokenId);
    nftSwap.list(address(testNFT), tokenId, 1 ether);
    vm.stopPrank();
    assertEq(testNFT.ownerOf(tokenId), address(nftSwap));
    (address owner, uint256 price) = nftSwap.orders(address(testNFT), tokenId);
    assertEq(owner, alice);
    assertEq(price, 1 ether);
  }

  function testRevoke() public {
    address alice = vm.addr(1);
    uint256 tokenId = 666;
    testNFT.mint(alice, tokenId);
    vm.startPrank(alice);
    testNFT.approve(address(nftSwap), tokenId);
    nftSwap.list(address(testNFT), tokenId, 1 ether);
    vm.expectEmit(true, true, true, true);
    emit Revoke(alice, address(testNFT), tokenId);
    nftSwap.revoke(address(testNFT), tokenId);
    vm.stopPrank();
  }

  function testUpdate() public {
    address alice = vm.addr(1);
    uint256 tokenId = 666;
    testNFT.mint(alice, tokenId);
    vm.startPrank(alice);
    testNFT.approve(address(nftSwap), tokenId);
    nftSwap.list(address(testNFT), tokenId, 1 ether);
    vm.expectEmit(true, true, true, true);
    emit Update(alice, address(testNFT), tokenId, 10 ether, 1 ether);
    nftSwap.update(address(testNFT), tokenId, 10 ether);
    vm.stopPrank();
  }

  function testPurchase() public {
    address alice = vm.addr(1);
    uint256 tokenId = 666;
    testNFT.mint(alice, tokenId);
    vm.startPrank(alice);
    testNFT.approve(address(nftSwap), tokenId);
    nftSwap.list(address(testNFT), tokenId, 1 ether);
    vm.stopPrank();

    address bob = vm.addr(2);
    vm.deal(alice, 0);
    vm.deal(bob, 10 ether);
    vm.expectEmit(true, true, true, true);
    emit Purchase(bob, address(testNFT), tokenId);
    vm.prank(bob);
    nftSwap.purchase{value: 10 ether}(address(testNFT), tokenId);
    assertEq(testNFT.ownerOf(tokenId), bob);
    assertEq(alice.balance, 1 ether);
    assertEq(bob.balance, 9 ether);
  }
}

