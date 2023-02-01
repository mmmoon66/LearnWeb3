// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
  constructor(string memory _name, string memory _symbol, uint256 _initialSupply) ERC20(_name, _symbol) {
    ERC20._mint(msg.sender, _initialSupply);
  }
}