// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {VestingWallet} from "../A43_VestingWallet.sol";
import {Test, console2} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract VestingWallet_Test is Test {
  address private immutable alice = vm.addr(1);
  VestingWallet private vestingWallet;
  TestERC20 private token;

  function setUp() public {
    console2.log("setUp, timestamp:", block.timestamp);
    vestingWallet = new VestingWallet({
    beneficiaryAddress : alice,
    startTimestamp : block.timestamp,
    durationSeconds : 365 days
    });
    (bool success,) = address(vestingWallet).call{value : 365 ether}("");
    require(success, "transfer ether to vestingWallet failed");
    assertEq(address(vestingWallet).balance, 365 ether);

    token = new TestERC20();
    token.transfer(address(vestingWallet), 365 ether);
    assertEq(token.balanceOf(address(vestingWallet)), 365 ether);
  }

  function testReleaseERC20() public {
    console2.log("testReleaseERC20, timestamp:", block.timestamp);
    uint256 timestamp = block.timestamp;

    vm.expectRevert("VestingWallet: releasable amount is zero");
    vestingWallet.release(address(token));

    vm.warp(timestamp + 1 days);
    vestingWallet.release(address(token));
    assertEq(token.balanceOf(alice), 1 ether);
    assertEq(token.balanceOf(address(vestingWallet)), 364 ether);

    vm.warp(timestamp + 365 days);
    vestingWallet.release(address(token));
    assertEq(token.balanceOf(alice), 365 ether);
    assertEq(token.balanceOf(address(vestingWallet)), 0);

    vm.expectRevert("VestingWallet: releasable amount is zero");
    vestingWallet.release(address(token));
  }

  function testReleaseEther() public {
    uint256 timestamp = block.timestamp;

    vm.expectRevert("VestingWallet: releasable amount is zero");
    vestingWallet.release();

    vm.warp(timestamp + 100 days);
    vestingWallet.release();
    assertEq(alice.balance, 100 ether);
    assertEq(address(vestingWallet).balance, 265 ether);

    vm.warp(timestamp + 365 days);
    vestingWallet.release();
    assertEq(alice.balance, 365 ether);
    assertEq(address(vestingWallet).balance, 0);

    vm.expectRevert("VestingWallet: releasable amount is zero");
    vestingWallet.release();
  }
}

contract TestERC20 is ERC20 {
  constructor() ERC20("Test Token", "TST") {
    ERC20._mint(msg.sender, 365 ether);
  }
}