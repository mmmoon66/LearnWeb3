// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract G1G2Token is ERC20, Ownable {
  constructor() ERC20("G1G2 Token", "G1G2") {
    ERC20._mint(_msgSender(), 1_000_000_000 * 1e18);
  }
}