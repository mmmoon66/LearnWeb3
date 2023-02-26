// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WETH is ERC20 {
  event Deposit(address indexed account, uint256 amount);
  event Withdraw(address indexed account, uint256 amount);

  constructor() ERC20("WETH", "WETH") {}

  receive() external payable {
    deposit();
  }

  fallback() external payable {
    deposit();
  }

  function deposit() public payable {
    require(msg.value > 0, "WETH: zero value");
    ERC20._mint(msg.sender, msg.value);
    emit Deposit(msg.sender, msg.value);
  }

  function withdraw(uint256 amount) public {
    require(amount > 0, "WETH: zero amount");
    require(amount <= balanceOf(msg.sender), "WETH: insufficient balance");
    ERC20._burn(msg.sender, amount);
    (bool success,) = msg.sender.call{value : amount}("");
    require(success, "WETH: transfer ETH failed");
    emit Withdraw(msg.sender, amount);
  }
}