// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library LibUQ112x112 {
  uint224 constant Q = 2 ** 112;

  function encode(uint112 y) internal pure returns (uint224 z) {
    z = uint224(y) * Q;
  }

  function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
    z = x / uint224(y);
  }
}