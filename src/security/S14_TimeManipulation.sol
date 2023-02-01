// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TimeManipulation is ERC721 {
  uint256 public totalSupply;

  constructor() ERC721("", "") {}

  function luckyMint() external returns (bool success) {
    if (block.timestamp % 170 == 0) {
      _mint(msg.sender, totalSupply++);
      success = true;
    } else {
      success = false;
    }
  }
}