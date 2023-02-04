// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERC20 {
  function allowance(address owner, address spender) external view returns (uint256);
}

contract Airdrop {
  function multiTransferETH(address[] memory accounts, uint256[] memory amounts) external payable {
    require(accounts.length > 0, "zero length");
    require(accounts.length == amounts.length, "length mismatch");
    require(msg.value >= _sum(amounts), "insufficient fund");
    uint256 len = accounts.length;

    uint256 succSum = 0;
    for (uint256 i = 0; i < len; ++i) {
      address account = accounts[i];
      uint256 amount = amounts[i];
      if (account != address(0) && amount > 0) {
        (bool success,) = account.call{value : amount}("");
        if (success) {
          succSum += amount;
        }
      }
    }
    if (msg.value > succSum) {
      (bool success,) = msg.sender.call{value : msg.value - succSum}("");
      require(success, "refund failed");
    }
  }

  function multiTransferToken(address token, address[] memory accounts, uint256[] memory amounts) external {
    require(token != address(0), "invalid token");
    require(accounts.length > 0, "zero length");
    require(accounts.length == amounts.length, "length mismatch");
    require(IERC20(token).allowance(msg.sender, address(this)) >= _sum(amounts), "insufficient allowance");
    uint256 len = accounts.length;
    for (uint256 i = 0; i < len; ++i) {
      address account = accounts[i];
      uint256 amount = amounts[i];
      bool success = _safeTransferFrom(token, msg.sender, account, amount);
    }
  }

  function _safeTransferFrom(address token, address from, address to, uint256 amount) private returns (bool succ) {
    succ = false;
    if (from != address(0) && to != address(0) && amount > 0) {
      (bool success, bytes memory data) = token.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, amount));
      succ = success;
      if (success && data.length > 0) {
        succ = abi.decode(data, (bool));
      }
    }
  }

  function _sum(uint256[] memory amounts) private pure returns (uint256) {
    uint256 sum = 0;
    uint256 len = amounts.length;
    for (uint256 i = 0; i < len; ++i) {
      sum += amounts[i];
    }
    return sum;
  }
}