// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Faucet} from "../A32_Faucet.sol";

contract TestToken is ERC20, Ownable {
  constructor() ERC20("Test Token", "TKN") {}

  function mint(address to, uint256 amount) external onlyOwner {
    _mint(to, amount);
  }
}

contract Faucet_Test is Test {
  function testFaucet() public {
    TestToken token = new TestToken();
    Faucet faucet = new Faucet(address(token), 100);
    token.mint(address(faucet), 200);

    address alice = vm.addr(1);
    vm.prank(alice);
    faucet.requestTokens();
    assertEq(token.balanceOf(alice), 100);
    vm.expectRevert("already requested");
    vm.prank(alice);
    faucet.requestTokens();

    address bob = vm.addr(2);
    vm.prank(bob);
    faucet.requestTokens();
    assertEq(token.balanceOf(bob), 100);

    address david = vm.addr(3);
    vm.expectRevert("faucet is empty");
    vm.prank(david);
    faucet.requestTokens();
  }
}