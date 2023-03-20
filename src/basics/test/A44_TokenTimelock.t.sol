// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TokenTimelock} from "../A44_TokenTimelock.sol";
import {Test} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TokenTimelock_Test is Test {
  TokenTimelock private tokenTimelock;
  TestToken private token;
  address private immutable alice = vm.addr(1);

  function setUp() public {
    token = new TestToken();
    tokenTimelock = new TokenTimelock(alice, address(token), block.timestamp + 365 days);

    SafeERC20.safeTransfer(token, address(tokenTimelock), 10000 ether);
    assertEq(token.balanceOf(address(tokenTimelock)), 10000 ether);
  }

  function testRelease() public {
    uint256 timestamp = block.timestamp;

    vm.warp(timestamp + 100 days);
    vm.expectRevert("TokenTimelock: not yet to release time");
    tokenTimelock.release();

    vm.warp(timestamp + 365 days);
    tokenTimelock.release();
    assertEq(token.balanceOf(address(tokenTimelock)), 0);
    assertEq(token.balanceOf(alice), 10000 ether);
  }
}

contract TestToken is ERC20 {
  constructor() ERC20("Test Token", "TST") {
    ERC20._mint(msg.sender, 10000 ether);
  }
}

