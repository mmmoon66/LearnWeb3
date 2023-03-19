// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VestingWallet {
  event ERC20Released(address indexed token, uint256 amount);
  event EtherReleased(uint256 amount);

  address private immutable _beneficiary;
  uint256 private immutable _start;
  uint256 private immutable _duration;
  uint256 private _etherReleased;
  // token address => released amount
  mapping(address => uint256) _erc20Released;

  receive() external payable {}

  constructor(
    address beneficiary,
    uint256 startTimestamp,
    uint256 durationSeconds
  ) {
    require(beneficiary != address(0), "VestingWallet: beneficiary is zero address");
    _beneficiary = beneficiary;
    _start = startTimestamp;
    _duration = durationSeconds;
  }

  function beneficiary() public view returns (address) {
    return _beneficiary;
  }

  function start() public view returns (uint256) {
    return _start;
  }

  function duration() public view returns (uint256) {
    return _duration;
  }

  function releaseERC20(address token) public {
    require(msg.sender == _beneficiary, "VestingWallet: sender not beneficiary");
    uint256 releasableAmount = _releasableERC20Amount(token);
    require(releasableAmount > 0, "VestingWallet: releasable amount is zero");
    _erc20Released[token] += releasableAmount;
    IERC20(token).transfer(msg.sender, releasableAmount);
    emit ERC20Released(token, releasableAmount);
  }

  function releaseEther() public {
    require(msg.sender == _beneficiary, "VestingWallet: sender not beneficiary");
    uint256 releasableAmount = _releasableEtherAmount();
    require(releasableAmount > 0, "VestingWallet: releasable amount is zero");
    _etherReleased += releasableAmount;
    (bool success,) = msg.sender.call{value : releasableAmount}("");
    require(success, "VestingWallet: transfer ether failed");
    emit EtherReleased(releasableAmount);
  }

  function _releasableERC20Amount(address token) private returns (uint256) {
    if (block.timestamp <= _start) {
      return 0;
    } else if (block.timestamp >= _start + _duration) {
      return IERC20(token).balanceOf(address(this));
    } else {
      uint256 totalAmount = IERC20(token).balanceOf(address(this)) + _erc20Released[token];
      return totalAmount * (block.timestamp - _start) / _duration - _erc20Released[token];
    }
  }

  function _releasableEtherAmount() private returns (uint256) {
    if (block.timestamp <= _start) {
      return 0;
    } else if (block.timestamp >= _start + _duration) {
      return address(this).balance;
    } else {
      uint256 totalAmount = address(this).balance + _etherReleased;
      return totalAmount * (block.timestamp - _start) / _duration - _etherReleased;
    }
  }

}