// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract FreeMint is ERC721 {

  uint256 public totalSupply;

  constructor() ERC721("Free Mint", "FM") {}

  function mint() external {
    _mint(msg.sender, totalSupply);
    totalSupply++;
  }
}
