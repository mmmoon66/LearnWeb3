// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/A31_ERC20.sol";

contract TestERC20 is ERC20 {
  constructor() ERC20("Test Token", "TKN", 18) {
    _mint(msg.sender, 10 ** 9 * 1e18);
  }
}

contract ERC20_Test is Test {
  TestERC20 private token;

  function setUp() public {
    token = new TestERC20();
  }

  function testMetadata() public {
    assertEq(token.name(), "Test Token");
    assertEq(token.symbol(), "TKN");
    assertEq(token.decimals(), 18);
  }
}