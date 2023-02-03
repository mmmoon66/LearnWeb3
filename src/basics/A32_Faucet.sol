// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Faucet {
  event TokenSent(uint256 amount);

  uint256 public immutable amountAllowed;
  mapping(address => bool) public requestedUsers;
  address public tokenAddress;

  constructor(address tokenAddress_, uint256 amountAllowed_) {
    tokenAddress = tokenAddress_;
    amountAllowed = amountAllowed_;
  }

  // Checks - Effects - Interactions
  function requestTokens() external {
    require(requestedUsers[msg.sender] == false, "already requested");
    require(IERC20(tokenAddress).balanceOf(address(this)) >= amountAllowed, "faucet is empty");
    requestedUsers[msg.sender] = true;
    bool success = IERC20(tokenAddress).transfer(msg.sender, amountAllowed);
    require(success, "transfer failed");
    emit TokenSent(amountAllowed);
  }
}