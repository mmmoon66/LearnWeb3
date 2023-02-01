// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Exchange} from "./Exchange.sol";

interface IFactory {
  function getExchange(address token) external view returns (address);
}

contract Factory is IFactory {
  mapping(address => address) private _tokenToExchange;

  function createExchange(address token) public returns (address) {
    require(token != address(0), "valid token address");
    require(_tokenToExchange[token] == address(0), "exchange already exist");
    Exchange exchange = new Exchange(token);
    _tokenToExchange[token] = address(exchange);
    return address(exchange);
  }

  function getExchange(address token) public view returns (address) {
    return _tokenToExchange[token];
  }
}