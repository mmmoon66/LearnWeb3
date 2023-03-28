// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Timelock} from "../A45_Timelock.sol";
import {Test} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract TestToken is ERC20, Ownable {
  event Mint(address indexed to, uint256 amount);

  constructor() ERC20("Test Token", "TST") {
  }

  function mint(address to, uint256 amount) external onlyOwner {
    ERC20._mint(to, amount);
    emit Mint(to, amount);
  }
}

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

  function testMintByTimelock() public {
    uint256 timestamp = block.timestamp;

    TestToken token = new TestToken();
    assertEq(token.owner(), address(this));

    token.transferOwnership(address(timelock));
    assertEq(token.owner(), address(timelock));

    address target = address(token);
    uint256 value = 0;
    string memory signature = "mint(address,uint256)";
    bytes memory data = abi.encode(alice, 1 ether);
    uint256 executeTime = timestamp + 7 days;
    timelock.queueTransaction(target, value, signature, data, executeTime);

    vm.warp(executeTime - 1 days);
    vm.expectRevert("Timelock: current time is before executeTime");
    timelock.executeTransaction(target, value, signature, data, executeTime);

    vm.warp(executeTime);
    timelock.executeTransaction(target, value, signature, data, executeTime);
    assertEq(token.balanceOf(alice), 1 ether);
  }
}