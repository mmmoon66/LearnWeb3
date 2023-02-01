// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "solmate/tokens/ERC20.sol";

contract MintableERC20 is ERC20 {
  error NotOwner();
  error InvalidAmount();

  address public owner;

  modifier onlyOwner() {
    if (msg.sender != owner) revert NotOwner();
    _;
  }

  constructor(string memory name, string memory symbol, uint8 decimals) ERC20(name, symbol, decimals) {
    owner = msg.sender;
  }

  function mint(address to, uint256 amount) external onlyOwner {
    if (amount == 0) revert InvalidAmount();
    _mint(to, amount);
  }
}