// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Bank, Attacker} from "../S01_ReentrancyAttack.sol";
import {Test} from "forge-std/Test.sol";

contract ReentrancyAttack_Test is Test {
  address private immutable alice = vm.addr(1);
  address private immutable bob = vm.addr(2);
  Bank private bank;

  function setUp() public {
    bank = new Bank();
    deal(alice, 10 ether);
    vm.prank(alice);
    bank.deposit{value : 10 ether}();
    assertEq(bank.balanceOf(alice), 10 ether);
  }

  function testReentrancyAttack() public {
    Attacker attacker = new Attacker(address(bank), bob);
    attacker.attack{value : 1 ether}();
    assertEq(address(bank).balance, 0);
    assertEq(address(attacker).balance, 11 ether);

    attacker.withdraw();
    assertEq(bob.balance, 11 ether);
    assertEq(address(attacker).balance, 0);
  }
}