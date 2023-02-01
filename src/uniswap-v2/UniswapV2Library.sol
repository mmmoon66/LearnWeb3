// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {UniswapV2Pair, IUniswapV2Pair} from "./UniswapV2Pair.sol";

library UniswapV2Library {
  error InsufficientAmount();
  error InsufficientLiquidity();
  error InvalidPath();


  function getReserves(
    address factoryAddress,
    address tokenA,
    address tokenB
  ) internal view returns (uint112 reserveA, uint112 reserveB) {
    (address token0,) = sortTokens(tokenA, tokenB);
    address pairAddress = pairFor(factoryAddress, tokenA, tokenB);
    (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(pairAddress).getReserves();
    (reserveA, reserveB) = token0 == tokenA ? (reserve0, reserve1) : (reserve1, reserve0);
  }

  function quote(
    uint256 amountIn,
    uint112 reserveIn,
    uint112 reserveOut
  ) internal pure returns (uint256 amountOut) {
    if (amountIn == 0) revert InsufficientAmount();
    if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();
    return amountIn * reserveOut / reserveIn;
  }

  function pairFor(
    address factoryAddress,
    address tokenA,
    address tokenB
  ) internal pure returns (address pairAddress) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    bytes memory bytecode = type(UniswapV2Pair).creationCode;
    bytes32 salt = keccak256(abi.encodePacked(token0, token1));
    pairAddress = address(
      uint160(
        uint256(
          keccak256(abi.encodePacked(
            hex"ff",
            factoryAddress,
            salt,
            keccak256(bytecode)
          ))
        )
      )
    );
  }

  function sortTokens(
    address tokenA,
    address tokenB
  ) internal pure returns (address token0, address token1) {
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
  }

  // (reserveIn + amountIn) * (reserveOut - amountOut) = reserveIn * reserveOut
  // => amountOut = amountIn * reserveOut / (reserveIn + amountIn)
  // and need take 0.3% amountIn as fee
  function getAmountOut(
    uint256 amountIn,
    uint112 reserveIn,
    uint112 reserveOut
  ) internal pure returns (uint256 amountOut) {
    if (amountIn == 0) revert InsufficientAmount();
    if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();
    uint256 amountInWithFee = amountIn * 997;
    amountOut = amountInWithFee * reserveOut / (reserveIn * 1000 + amountInWithFee);
  }

  function getAmountsOut(
    uint256 amountIn,
    address[] memory path,
    address factory
  ) internal view returns (uint256[] memory) {
    if (path.length < 2) revert InvalidPath();
    uint256[] memory amounts = new uint256[](path.length);
    amounts[0] = amountIn;
    for (uint256 i = 0; i < path.length - 1; i += 1) {
      address tokenA = path[i];
      address tokenB = path[i + 1];
      (uint112 reserveA, uint112 reserveB) = getReserves(factory, tokenA, tokenB);
      amounts[i + 1] = getAmountOut(amounts[i], reserveA, reserveB);
    }
    return amounts;
  }

  function getAmountIn(
    uint256 amountOut,
    uint112 reserveIn,
    uint112 reserveOut
  ) internal pure returns (uint256 amountIn) {
    if (amountOut == 0) revert InsufficientAmount();
    if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();
    // (1000*reserveIn + 997*amountIn) * (reverseOut - amountOut) = 1000*reserveIn * reserveOut
    uint256 numerator = amountOut * reserveIn * 1000;
    uint256 denominator = (reserveOut - amountOut) * 997;
    amountIn = numerator / denominator + 1;
  }

  function getAmountsIn(
    uint256 amountOut,
    address[] memory path,
    address factory
  ) internal view returns (uint256[] memory) {
    if (path.length < 2) revert InvalidPath();
    uint256[] memory amounts = new uint256[](path.length);
    amounts[path.length - 1] = amountOut;
    for (uint i = path.length - 1; i >= 1; i -= 1) {
      address tokenA = path[i - 1];
      address tokenB = path[i];
      (uint112 reserveA, uint112 reserveB) = getReserves(factory, tokenA, tokenB);
      amounts[i - 1] = getAmountIn(amounts[i], reserveA, reserveB);
    }
    return amounts;
  }
}