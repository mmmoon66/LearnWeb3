// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {PaymentSplit} from "../A42_PaymentSplit.sol";

contract PaymentSplit_Test is Test {
  event PaymentReceived(address indexed from, uint256 amount);
  event PaymentReleased(address indexed to, uint256 amount);

  PaymentSplit public paymentSplit;
  address alice = vm.addr(1);
  address bob = vm.addr(2);

  function setUp() public {
    address[] memory payees = new address[](2);
    payees[0] = alice;
    payees[1] = bob;
    uint256[] memory shares = new uint256[](2);
    shares[0] = 2;
    shares[1] = 3;
    paymentSplit = new PaymentSplit(payees, shares);
  }

  function testReceive(uint256 amount) public {
    deal(address(this), amount);
    vm.expectEmit(true, true, true, true);
    emit PaymentReceived(address(this), amount);
    (bool success,) = address(paymentSplit).call{value : amount}("");
    assert(success);
    assertEq(address(paymentSplit).balance, amount);
    assertEq(address(this).balance, 0);
  }

  function testRelease() public {
    (bool success,) = address(paymentSplit).call{value : 5 ether}("");
    assert(success);
    vm.expectEmit(true, true, true, true);
    emit PaymentReleased(alice, 2 ether);
    paymentSplit.release(alice);
    assertEq(paymentSplit.totalReleased(), 2 ether);
    assertEq(paymentSplit.released(alice), 2 ether);
    assertEq(alice.balance, 2 ether);

    (success,) = address(paymentSplit).call{value : 1 ether}("");
    assert(success);
    vm.expectEmit(true, true, true, true);
    emit PaymentReleased(bob, 3.6 ether);
    paymentSplit.release(bob);
    assertEq(paymentSplit.totalReleased(), 5.6 ether);
    assertEq(paymentSplit.released(bob), 3.6 ether);
    assertEq(bob.balance, 3.6 ether);
  }
}