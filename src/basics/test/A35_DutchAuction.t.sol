// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console, Test} from "forge-std/Test.sol";
import {DutchAuction} from "../A35_DutchAuction.sol";

contract DutchAuction_Test is Test {
  DutchAuction private auction;

  function setUp() public {
    auction = new DutchAuction();
    console.log("auctionStartTime:", auction.auctionStartTime());
  }

  function testGetAuctionPrice() public {
    uint256 currentTime = block.timestamp;
    console.log("block.timestamp:", block.timestamp);
    assertEq(auction.getAuctionPrice(), 1 ether);

    vm.warp(currentTime + 59 seconds);
    console.log("block.timestamp:", block.timestamp);
    assertEq(auction.getAuctionPrice(), 1 ether);

    vm.warp(currentTime + 1 minutes);
    assertEq(auction.getAuctionPrice(), 1 ether - 0.09 ether);

    vm.warp(currentTime + 5 minutes + 30 seconds);
    assertEq(auction.getAuctionPrice(), 1 ether - 0.09 ether * 5);

    vm.warp(currentTime + 10 minutes);
    assertEq(auction.getAuctionPrice(), 0.1 ether);
  }

  function testAuctionMint() public {
    uint256 currentTime = block.timestamp;
    address alice = vm.addr(1);
    deal(alice, 10000 ether);
    vm.warp(currentTime + 5 minutes);
    vm.prank(alice);
    auction.auctionMint{value : 3000 ether}(3000);
    uint256 aliceCost = auction.getAuctionPrice() * 3000;
    console.log("aliceCost:", aliceCost);
    assertEq(auction.balanceOf(alice), 3000);
    assertEq(auction.totalSupply(), 3000);
    assertEq(alice.balance, 10000 ether - aliceCost);
    assertEq(address(auction).balance, aliceCost);

    address bob = vm.addr(2);
    deal(bob, 10000 ether);
    vm.warp(currentTime + 20 minutes);
    vm.prank(bob);
    auction.auctionMint{value : 7000 ether}(7000);
    uint256 bobCost = auction.getAuctionPrice() * 7000;
    console.log("bobCost:", bobCost);
    assertEq(auction.balanceOf(bob), 7000);
    assertEq(auction.totalSupply(), 10000);
    assertEq(bob.balance, 10000 ether - bobCost);
    assertEq(address(auction).balance, aliceCost + bobCost);

    address edward = vm.addr(3);
    deal(edward, 1 ether);
    vm.warp(currentTime + 30 minutes);
    vm.prank(edward);
    vm.expectRevert("exceed max supply");
    auction.auctionMint(10);

    deal(address(this), 0);
    auction.withdraw();
    assertEq(address(this).balance, aliceCost + bobCost);
    assertEq(address(auction).balance, 0);
  }

  receive() external payable {}
}