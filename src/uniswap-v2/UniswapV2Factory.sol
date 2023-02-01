// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {UniswapV2Pair} from "./UniswapV2Pair.sol";

interface IUniswapV2Factory {
  function pairs(address tokenA, address tokenB) external view returns (address pair);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract UniswapV2Factory is IUniswapV2Factory {
  error IdenticalAddresses();
  error PairExists();
  error ZeroAddress();

  event PairCreated(
    address indexed token0,
    address indexed token1,
    address indexed pair,
    uint256 pairsCount
  );

  mapping(address => mapping(address => address)) public pairs;
  address[] public allPairs;

  function createPair(address tokenA, address tokenB) public returns (address pair) {
    if (tokenA == tokenB) revert IdenticalAddresses();
    (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    if (token0 == address(0)) revert ZeroAddress();
    if (pairs[token0][token1] != address(0)) revert PairExists();

    bytes32 salt = keccak256(abi.encodePacked(token0, token1));
    UniswapV2Pair uniswapV2Pair = new UniswapV2Pair{salt : salt}();
    uniswapV2Pair.initialize(token0, token1);
    pair = address(uniswapV2Pair);
    pairs[token0][token1] = pair;
    pairs[token1][token0] = pair;
    allPairs.push(pair);
    emit PairCreated(token0, token1, pair, allPairs.length);
  }
}