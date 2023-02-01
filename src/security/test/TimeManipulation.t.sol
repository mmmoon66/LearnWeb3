// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TimeManipulation} from "../S14_TimeManipulation.sol";

contract TimeManipulation_Test is Test {
  TimeManipulation private _nft;

  function setUp() public {
    _nft = new TimeManipulation();
  }

  function testLuckyMint() public {
    assertEq(_nft.balanceOf(address(this)), 0);
    vm.warp(169);
    console.log("block.timestamp:", block.timestamp);
    bool success = _nft.luckyMint();
    assert(success == false);
    assertEq(_nft.balanceOf(address(this)), 0);

    vm.warp(170);
    console.log("block.timestamp:", block.timestamp);
    success = _nft.luckyMint();
    assert(success == true);
    assertEq(_nft.balanceOf(address(this)), 1);
  }
}