// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TokenTimelock {
  using SafeERC20 for IERC20;

  event TokenLocked(address indexed beneficiary, address indexed token, uint256 unlockTimestamp);
  event TokenUnlocked(address indexed benefiary, address indexed token, uint256 amount);

  address private immutable _beneficiary;
  address private immutable _token;
  uint256 private immutable _unlockTimestamp;

  constructor(
    address beneficiary_,
    address token_,
    uint256 unlockTimestamp_
  ) {
    require(beneficiary_ != address(0), "TokenTimelock: beneficiary is zero address");
    require(unlockTimestamp_ >= block.timestamp, "TokenTimelock: unlock timestamp is before current timestamp");
    _beneficiary = beneficiary_;
    _token = token_;
    _unlockTimestamp = unlockTimestamp_;
    emit TokenLocked(beneficiary_, token_, unlockTimestamp_);
  }

  function beneficiary() public view virtual returns (address) {
    return _beneficiary;
  }

  function token() public view virtual returns (IERC20) {
    return IERC20(_token);
  }

  function unlockTimestamp() public view virtual returns (uint256) {
    return _unlockTimestamp;
  }

  function release() public {
    require(block.timestamp >= unlockTimestamp(), "TokenTimelock: not yet to unlock time");
    uint256 balance = token().balanceOf(address(this));
    require(balance > 0, "TokenTimelock: balance is zero");
    emit TokenUnlocked(beneficiary(), address(token()), balance);
    token().safeTransfer(beneficiary(), balance);
  }
}