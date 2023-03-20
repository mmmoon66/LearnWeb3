// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TokenTimelock {
  using SafeERC20 for IERC20;

  address private immutable _beneficiary;
  address private immutable _token;
  uint256 private immutable _releaseTimestamp;

  constructor(
    address beneficiary_,
    address token_,
    uint256 releaseTimestamp_
  ) {
    require(beneficiary_ != address(0), "TokenTimelock: beneficiary is zero address");
    require(releaseTimestamp_ > block.timestamp, "TokenTimelock: release timestamp is before current timestamp");
    _beneficiary = beneficiary_;
    _token = token_;
    _releaseTimestamp = releaseTimestamp_;
  }

  function beneficiary() public view virtual returns (address) {
    return _beneficiary;
  }

  function token() public view virtual returns (IERC20) {
    return IERC20(_token);
  }

  function releaseTimestamp() public view virtual returns (uint256) {
    return _releaseTimestamp;
  }

  function release() public virtual {
    require(block.timestamp >= releaseTimestamp(), "TokenTimelock: not yet to release time");
    uint256 balance = token().balanceOf(address(this));
    require(balance > 0, "TokenTimelock: balance is zero");
    token().safeTransfer(beneficiary(), balance);
  }
}