// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract TestToken is ERC20, Ownable {
  constructor() ERC20("Test Token", "TKN") {}

  function mint(address to, uint256 amount) external onlyOwner {
    ERC20._mint(to, amount);
  }
}

contract ApproveScam is Test {
  TestToken private token;
  address private alice = address(100);
  address private bob = address(200);

  function setUp() public {
    token = new TestToken();
  }

  function testApproveScam() public {
    token.mint(alice, 1000);

    console.log("Before approve, alice's balance: ", token.balanceOf(alice));
    console.log("Before approve, bob's balance: ", token.balanceOf(bob));

    vm.startPrank(alice);
    token.approve(bob, type(uint256).max);
    vm.stopPrank();
    assertEq(token.allowance(alice, bob), type(uint256).max);

    vm.startPrank(bob);
    token.transferFrom(alice, bob, token.balanceOf(alice));
    vm.stopPrank();

    console.log("After transferFrom, alice's balance: ", token.balanceOf(alice));
    console.log("After transferFrom, bob's balance: ", token.balanceOf(bob));
  }
}
