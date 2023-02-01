// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IUniswapV2Factory} from "./UniswapV2Factory.sol";
import {IERC20, IUniswapV2Pair} from "./UniswapV2Pair.sol";
import {UniswapV2Library} from "./UniswapV2Library.sol";

contract UniswapV2Router {
  error InsufficientAAmount();
  error InsufficientBAmount();
  error SafeTransferFailed();
  error InsufficientOutputAmount();
  error ExcessiveInputAmount();


  IUniswapV2Factory factory;

  constructor(address factoryAddress) {
    factory = IUniswapV2Factory(factoryAddress);
  }

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to
  ) public returns (
    uint256 amountA,
    uint256 amountB,
    uint256 liquidity
  ) {
    address pair = factory.pairs(tokenA, tokenB);
    if (pair == address(0)) {
      pair = factory.createPair(tokenA, tokenB);
    }
    (amountA, amountB) = _calculateLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
    _safeTransferFrom(tokenA, msg.sender, pair, amountA);
    _safeTransferFrom(tokenB, msg.sender, pair, amountB);
    liquidity = IUniswapV2Pair(pair).mint(to);
  }

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to
  ) public returns (uint256 amountA, uint256 amountB) {
    address pair = factory.pairs(tokenA, tokenB);
    assert(pair != address(0));
    _safeTransferFrom(pair, msg.sender, pair, liquidity);
    (uint256 amount0, uint256 amount1) = IUniswapV2Pair(pair).burn(to);
    (amountA, amountB) = tokenA < tokenB ? (amount0, amount1) : (amount1, amount0);
    if (amountA < amountAMin) revert InsufficientAAmount();
    if (amountB < amountBMin) revert InsufficientBAmount();
  }

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to
  ) public returns (uint256[] memory) {
    uint256[] memory amountsOut = UniswapV2Library.getAmountsOut(amountIn, path, address(factory));
    uint256 amountOut = amountsOut[amountsOut.length - 1];
    if (amountOut < amountOutMin) revert InsufficientOutputAmount();
    _safeTransferFrom(
      path[0],
      msg.sender,
      UniswapV2Library.pairFor(address(factory), path[0], path[1]),
      amountIn
    );
    _swap(amountsOut, path, to);
    return amountsOut;
  }

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to
  ) public returns (uint256[] memory) {
    uint256[] memory amountsIn = UniswapV2Library.getAmountsIn(amountOut, path, address(factory));
    uint256 amountIn = amountsIn[0];
    if (amountIn > amountInMax) revert ExcessiveInputAmount();
    _safeTransferFrom(
      path[0],
      msg.sender,
      UniswapV2Library.pairFor(address(factory), path[0], path[1]),
      amountIn
    );
    _swap(amountsIn, path, to);
    return amountsIn;
  }

  function _swap(
    uint256[] memory amounts,
    address[] memory path,
    address to
  ) private {
    for (uint256 i = 0; i < path.length - 1; i += 1) {
      (address tokenInput, address tokenOutput) = (path[i], path[i + 1]);
      uint256 amountOut = amounts[i + 1];
      (address token0, address token1) = UniswapV2Library.sortTokens(tokenInput, tokenOutput);
      uint256 amount0Out = token0 == tokenInput ? 0 : amountOut;
      uint256 amount1Out = token1 == tokenInput ? 0 : amountOut;
      address to_ = i == path.length - 2 ? to : UniswapV2Library.pairFor(address(factory), path[i + 1], path[i + 2]);
      address pair = UniswapV2Library.pairFor(address(factory), tokenInput, tokenOutput);
      IUniswapV2Pair(pair).swap(amount0Out, amount1Out, to_, "");
    }
  }

  function _calculateLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin
  ) private view returns (
    uint256 amountA,
    uint256 amountB
  ) {
    (uint112 reserveA, uint112 reserveB) = UniswapV2Library.getReserves(address(factory), tokenA, tokenB);
    if (reserveA == 0 && reserveB == 0) {
      amountA = amountADesired;
      amountB = amountBDesired;
    } else {
      uint256 amountBOptimal = UniswapV2Library.quote(amountA, reserveA, reserveB);
      if (amountBOptimal <= amountBDesired) {
        if (amountBOptimal < amountBMin) {
          revert InsufficientBAmount();
        }
        amountA = amountADesired;
        amountB = amountBOptimal;
      } else {
        uint256 amountAOptimal = UniswapV2Library.quote(amountB, reserveB, reserveA);
        assert(amountAOptimal <= amountADesired);
        if (amountAOptimal < amountAMin) {
          revert InsufficientAAmount();
        }
        amountA = amountAOptimal;
        amountB = amountBDesired;
      }
    }
  }

  function _safeTransferFrom(address token, address from, address to, uint256 amount) private {
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSignature(
        "transferFrom(address,address,uint256)",
        from,
        to,
        amount
      )
    );
    if (!success || !abi.decode(data, (bool))) {
      revert SafeTransferFailed();
    }
  }
}