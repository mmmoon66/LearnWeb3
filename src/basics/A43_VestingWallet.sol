// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract VestingWallet {
  event ERC20Released(address indexed token, uint256 amount);
  event EtherReleased(uint256 amount);

  address private immutable _beneficiary;
  uint256 private immutable _start;
  uint256 private immutable _duration;
  uint256 private _etherReleased;
  // token address => released amount
  mapping(address => uint256) _erc20Released;

  receive() external payable virtual {}

  constructor(
    address beneficiaryAddress,
    uint256 startTimestamp,
    uint256 durationSeconds
  ) {
    require(beneficiaryAddress != address(0), "VestingWallet: beneficiary is zero address");
    _beneficiary = beneficiaryAddress;
    _start = startTimestamp;
    _duration = durationSeconds;
  }

  function beneficiary() public view virtual returns (address) {
    return _beneficiary;
  }

  function start() public view virtual returns (uint256) {
    return _start;
  }

  function duration() public view virtual returns (uint256) {
    return _duration;
  }

  function released() public view virtual returns (uint256) {
    return _etherReleased;
  }

  function released(address token) public view virtual returns (uint256) {
    return _erc20Released[token];
  }

  function release() public virtual {
    uint256 releasableAmount = releasable();
    require(releasableAmount > 0, "VestingWallet: releasable amount is zero");
    _etherReleased += releasableAmount;
    emit EtherReleased(releasableAmount);
    (bool success,) = beneficiary().call{value : releasableAmount}("");
    require(success, "VestingWallet: transfer ether failed");
  }

  function release(address token) public virtual {
    uint256 releasableAmount = releasable(token);
    require(releasableAmount > 0, "VestingWallet: releasable amount is zero");
    _erc20Released[token] += releasableAmount;
    emit ERC20Released(token, releasableAmount);
    SafeERC20.safeTransfer(IERC20(token), beneficiary(), releasableAmount);
  }

  function releasable() public view virtual returns (uint256) {
    return vestedAmount(block.timestamp) - released();
  }

  function releasable(address token) public view virtual returns (uint256) {
    return vestedAmount(token, block.timestamp) - released(token);
  }

  function vestedAmount(uint256 timestamp) public view virtual returns (uint256) {
    return _vestingSchedule(address(this).balance + released(), timestamp);
  }

  function vestedAmount(address token, uint256 timestamp) public view virtual returns (uint256) {
    return _vestingSchedule(IERC20(token).balanceOf(address(this)) + released(token), timestamp);
  }

  function _vestingSchedule(uint256 totalAllocation, uint256 timestamp) internal view virtual returns (uint256) {
    if (timestamp <= start()) {
      return 0;
    } else if (timestamp >= start() + duration()) {
      return totalAllocation;
    } else {
      return totalAllocation * (timestamp - start()) / duration();
    }
  }
}