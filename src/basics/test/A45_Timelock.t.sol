// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Timelock} from "../A45_Timelock.sol";
import {Test} from "forge-std/Test.sol";

contract Timelock_Test is Test {

  address private immutable alice = vm.addr(1);
  Timelock private timelock;

  function setUp() public {
    timelock = new Timelock(3 days);
  }

  function testChangeAdminRevert() public {
    vm.expectRevert("Timelock: sender not time lock");
    timelock.changeAdmin(alice);
  }

  function testCancelTransaction() public {
    address target = address(timelock);
    uint256 value = 0;
    string memory signature = "changeAdmin(address)";
    bytes memory data = abi.encode(alice);
    uint256 executeTime = block.timestamp + 7 days;
    timelock.queueTransaction(target, value, signature, data, executeTime);

    vm.warp(block.timestamp + 1 days);
    timelock.cancelTransaction(target, value, signature, data, executeTime);
  }

  function testExecuteTransaction() public {
    uint256 timestamp = block.timestamp;

    address target = address(timelock);
    uint256 value = 0;
    string memory signature = "changeAdmin(address)";
    bytes memory data = abi.encode(alice);
    uint256 executeTime = timestamp + 7 days;
    timelock.queueTransaction(target, value, signature, data, executeTime);

    vm.warp(executeTime - 1 days);
    vm.expectRevert("Timelock: current time is before executeTime");
    timelock.executeTransaction(target, value, signature, data, executeTime);

    vm.warp(executeTime + 8 days);
    vm.expectRevert("Timelock: tx is expired");
    timelock.executeTransaction(target, value, signature, data, executeTime);

    vm.warp(executeTime);
    timelock.executeTransaction(target, value, signature, data, executeTime);
    assertEq(timelock.admin(), alice);
  }
}