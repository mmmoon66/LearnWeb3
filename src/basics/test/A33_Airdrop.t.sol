// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Airdrop} from "../A33_Airdrop.sol";


contract Airdrop_Test is Test {
  Airdrop private airdrop;
  TestToken private token;

  function setUp() public {
    airdrop = new Airdrop();
    token = new TestToken();
  }

  function testMultiTransferETH() public {
    address[] memory accounts = new address[](3);
    accounts[0] = vm.addr(100);
    accounts[1] = vm.addr(101);
    accounts[2] = vm.addr(102);
    uint256[] memory amounts = new uint256[](3);
    amounts[0] = 1 ether;
    amounts[1] = 1 ether;
    amounts[2] = 1 ether;

    address alice = vm.addr(1);
    deal(alice, 10 ether);
    vm.prank(alice);
    airdrop.multiTransferETH{value : 10 ether}(accounts, amounts);
    assertEq(vm.addr(100).balance, 1 ether);
    assertEq(vm.addr(101).balance, 1 ether);
    assertEq(vm.addr(102).balance, 1 ether);
    assertEq(alice.balance, 7 ether);
  }

  function testMultiTransferETHIncludingDosAttacker() public {
    DosAttacker attacker = new DosAttacker();
    address[] memory accounts = new address[](3);
    accounts[0] = address(attacker);
    accounts[1] = vm.addr(101);
    accounts[2] = vm.addr(102);
    uint256[] memory amounts = new uint256[](3);
    amounts[0] = 1 ether;
    amounts[1] = 1 ether;
    amounts[2] = 1 ether;

    address alice = vm.addr(1);
    deal(alice, 10 ether);
    vm.prank(alice);
    airdrop.multiTransferETH{value : 10 ether}(accounts, amounts);
    assertEq(address(attacker).balance, 0);
    assertEq(vm.addr(101).balance, 1 ether);
    assertEq(vm.addr(102).balance, 1 ether);
    assertEq(alice.balance, 8 ether);
  }

  function testMultiTransferToken() public {
    address[] memory accounts = new address[](3);
    accounts[0] = vm.addr(100);
    accounts[1] = vm.addr(101);
    accounts[2] = vm.addr(102);
    uint256[] memory amounts = new uint256[](3);
    amounts[0] = 1 ether;
    amounts[1] = 1 ether;
    amounts[2] = 1 ether;

    address alice = vm.addr(1);
    token.mint(alice, 10 ether);
    vm.startPrank(alice);
    token.approve(address(airdrop), 10 ether);
    airdrop.multiTransferToken(address(token), accounts, amounts);
    vm.stopPrank();

    assertEq(token.balanceOf(vm.addr(100)), 1 ether);
    assertEq(token.balanceOf(vm.addr(101)), 1 ether);
    assertEq(token.balanceOf(vm.addr(102)), 1 ether);
    assertEq(token.balanceOf(alice), 7 ether);
  }

}

contract TestToken is ERC20, Ownable {
  constructor() ERC20("Test Token", "TKN") {}

  function mint(address to, uint256 amount) external onlyOwner {
    _mint(to, amount);
  }
}

contract DosAttacker {
  receive() external payable {
    revert("DoS attack");
  }
}