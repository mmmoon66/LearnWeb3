// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library LibMath {
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  function sqrt(uint256 n) internal pure returns (uint256) {
    if (n == 0) {
      return 0;
    }
    uint256 lo = 1;
    uint256 hi = n;
    while (lo < hi) {
      uint256 mid = lo + (hi - lo) / 2;
      uint256 p = mid * mid;
      if (p == n) {
        return mid;
      } else if (p < n) {
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return lo * lo <= n ? lo : lo - 1;
  }
}