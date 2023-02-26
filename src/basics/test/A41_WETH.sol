// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {WETH} from "../A41_WETH.sol";

contract WETH_Test is Test {

  WETH public weth;
  address public alice = address(666);

  function setUp() public {
    weth = new WETH();
  }

  function testDeposit(uint256 amount) public {
    deal(alice, amount);
    vm.prank(alice);
    if (amount == 0) {
      vm.expectRevert("WETH: zero value");
      weth.deposit{value : amount}();
    } else {
      weth.deposit{value : amount}();
      assertEq(alice.balance, 0);
      assertEq(weth.balanceOf(alice), amount);
    }
  }

  function testReceive(uint256 amount) public {
    deal(alice, amount);
    vm.prank(alice);
    if (amount == 0) {
      vm.expectRevert("WETH: zero value");
      address(weth).call{value : amount}("");
    } else {
      address(weth).call{value : amount}("");
      assertEq(alice.balance, 0);
      assertEq(weth.balanceOf(alice), amount);
    }
  }

  function testFallback(uint256 amount) public {
    deal(alice, amount);
    vm.prank(alice);
    bytes memory data = abi.encodeWithSignature("not_exist_function(uint256)", 666);
    if (amount == 0) {
      vm.expectRevert("WETH: zero value");
      address(weth).call{value : amount}(data);
    } else {
      address(weth).call{value : amount}(data);
      assertEq(alice.balance, 0);
      assertEq(weth.balanceOf(alice), amount);
    }
  }

  function testWithdraw(uint256 depositAmount, uint256 withdrawAmount) public {
    deal(alice, depositAmount);
    vm.assume(depositAmount > 0);
    vm.startPrank(alice);
    weth.deposit{value : depositAmount}();

    if (withdrawAmount == 0) {
      vm.expectRevert("WETH: zero amount");
      weth.withdraw(withdrawAmount);
    } else if (withdrawAmount <= depositAmount) {
      weth.withdraw(withdrawAmount);
      assertEq(alice.balance, withdrawAmount);
      assertEq(weth.balanceOf(alice), depositAmount - withdrawAmount);
    } else {
      vm.expectRevert("WETH: insufficient balance");
      weth.withdraw(withdrawAmount);
    }
    vm.stopPrank();
  }
}