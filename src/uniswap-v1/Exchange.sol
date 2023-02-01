// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IFactory} from "./Factory.sol";

interface IExchange {
  function ethToTokenSwap(uint256 minTokenAmount) external payable;

  function ethToTokenTransfer(uint256 minTokenAmount, address recipient) external payable;

  function addLiquidity(uint256 tokenAmount) external payable returns (uint256);

  function tokenToTokenSwap(uint256 tokenSold, uint256 tokenOutMin, address tokenOut) external;
}

contract Exchange is IExchange, ERC20 {
  address public tokenAddress;
  address public factoryAddress;

  constructor(address tokenAddress_) ERC20("Uniswap-V1", "UNI-V1") {
    require(tokenAddress_ != address(0), "invalid token address");
    tokenAddress = tokenAddress_;
    factoryAddress = msg.sender;
  }

  function addLiquidity(uint256 tokenAmount) external payable returns (uint256) {
    if (getReserve() == 0) {
      IERC20(tokenAddress).transferFrom(msg.sender, address(this), tokenAmount);
      uint256 liquidity = address(this).balance;
      _mint(msg.sender, liquidity);
      return liquidity;
    } else {
      uint256 ethAmount = msg.value;
      uint256 ethReserve = address(this).balance - msg.value;
      uint256 tokenReserve = getReserve();
      uint256 tokenAmount_ = ethAmount * tokenReserve / ethReserve;
      require(tokenAmount >= tokenAmount_, "insufficient token amount");
      IERC20(tokenAddress).transferFrom(msg.sender, address(this), tokenAmount_);
      uint256 liquidity = ethAmount * totalSupply() / ethReserve;
      _mint(msg.sender, liquidity);
      return liquidity;
    }
  }

  function removeLiquidity(uint256 lpTokenAmount) external returns (uint256 ethAmount, uint256 tokenAmount) {
    require(lpTokenAmount > 0, "invalid amount");
    uint256 ethReserve = address(this).balance;
    uint256 tokenReserve = getReserve();
    ethAmount = lpTokenAmount * ethReserve / totalSupply();
    tokenAmount = lpTokenAmount * tokenReserve / totalSupply();
    _burn(msg.sender, lpTokenAmount);
    payable(msg.sender).transfer(ethAmount);
    IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
  }

  function getReserve() public view returns (uint256) {
    return IERC20(tokenAddress).balanceOf(address(this));
  }

  //  function getPrice(uint256 inputReserve, uint256 outputReserve) public pure returns (uint256 outputPrice) {
  //    require(inputReserve > 0 && outputReserve > 0, "invalid reserves");
  //    outputPrice = 1000 * inputReserve / outputReserve;
  //  }

  // (x + dx) * (y - dy) = x * y => dy = (y * dx) / (x + dx)
  // take 1% as fee
  function _getAmount(
    uint256 inputAmount,
    uint256 inputReserve,
    uint256 outputReserve
  ) private pure returns (uint256 outputAmount) {
    require(inputReserve > 0 && outputReserve > 0, "invalid reserves");
    uint256 inputAmountWithFee = inputAmount * 99;
    uint256 numerator = outputReserve * inputAmountWithFee;
    uint256 dominator = (inputReserve * 100) + inputAmountWithFee;
    outputAmount = numerator / dominator;
  }

  function getTokenAmount(uint256 ethSold) public view returns (uint256) {
    uint256 ethReserve = address(this).balance;
    uint256 tokenReserve = getReserve();
    return _getAmount(ethSold, ethReserve, tokenReserve);
  }

  function getEthAmount(uint256 tokenSold) public view returns (uint256) {
    uint256 ethReserve = address(this).balance;
    uint256 tokenReserve = getReserve();
    return _getAmount(tokenSold, tokenReserve, ethReserve);
  }

  function ethToTokenSwap(uint256 minTokenAmount) public payable {
    _ethToToken(minTokenAmount, msg.sender);
  }

  function ethToTokenTransfer(uint256 minTokenAmount, address recipient) public payable {
    _ethToToken(minTokenAmount, recipient);
  }

  function _ethToToken(uint256 minTokenAmount, address recipient) private {
    uint256 ethSold = msg.value;
    uint256 ethReserve = address(this).balance - msg.value;
    uint256 tokenReserve = getReserve();
    uint256 tokenBought = _getAmount(ethSold, ethReserve, tokenReserve);
    require(tokenBought >= minTokenAmount, "insufficient output amount");
    IERC20(tokenAddress).transfer(recipient, tokenBought);
  }

  function tokenToEthSwap(uint256 tokenSold, uint256 minEthAmount) public {
    uint256 ethReserve = address(this).balance;
    uint256 tokenReserve = getReserve();
    uint256 ethBought = _getAmount(tokenSold, tokenReserve, ethReserve);
    require(ethBought >= minEthAmount, "insufficient output amount");
    IERC20(tokenAddress).transferFrom(msg.sender, address(this), tokenSold);
    payable(msg.sender).transfer(ethBought);
  }

  function tokenToTokenSwap(uint256 tokenSold, uint256 tokenOutMin, address tokenOut) public {
    address exchangeAddress = IFactory(factoryAddress).getExchange(tokenOut);
    require(exchangeAddress != address(this) && exchangeAddress != address(0), "exchange not exist");
    uint256 ethReserve = address(this).balance;
    uint256 tokenReserve = getReserve();
    uint256 ethAmount = _getAmount(tokenSold, tokenReserve, ethReserve);
    IERC20(tokenAddress).transferFrom(msg.sender, address(this), tokenSold);

    IExchange(exchangeAddress).ethToTokenTransfer{value : ethAmount}(tokenOutMin, msg.sender);
  }
}