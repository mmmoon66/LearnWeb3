// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2, Vm} from "forge-std/Test.sol";
import {Exchange, IExchange} from "../Exchange.sol";
import {Token} from "../Token.sol";
import {Factory} from "../Factory.sol";

contract ExchangeTest is Test {
  Token private _token;
  Exchange private _exchange;

  function setUp() public {
    //    console2.log("setUp, msg.sender:", msg.sender);
    _token = new Token("Token", "TKN", 10 ** 27);
    _exchange = new Exchange(address(_token));
  }

  function test_addLiquidity() public {
    //    console2.log("test_addLiquidity, msg.sender:", msg.sender);
    deal(msg.sender, 100 ether);
    deal(address(_token), msg.sender, 200 ether);

    assertEq(msg.sender.balance, 100 ether);
    assertEq(_token.balanceOf(msg.sender), 200 ether);

    _token.approve(address(_exchange), 200 ether);
    _exchange.addLiquidity{value : 100 ether}(200 ether);

    assertEq(address(_exchange).balance, 100 ether);
    assertEq(_exchange.getReserve(), 200 ether);
  }

  //  function test_getPrice() public {
  //    deal(msg.sender, 1000 ether);
  //    deal(address(_token), msg.sender, 2000 ether);
  //
  //    _token.approve(address(_exchange), 2000 ether);
  //    _exchange.addLiquidity{value: 1000 ether}(2000 ether);
  //
  //    uint256 etherReserve = address(_exchange).balance;
  //    uint256 tokenReserve = _exchange.getReserve();
  //    assertEq(_exchange.getPrice(etherReserve, tokenReserve), 500);
  //    assertEq(_exchange.getPrice(tokenReserve, etherReserve), 2000);
  //  }

  function test_getTokenAmount() public {
    deal(msg.sender, 1000 ether);
    deal(address(_token), msg.sender, 2000 ether);

    _token.approve(address(_exchange), 2000 ether);
    _exchange.addLiquidity{value : 1000 ether}(2000 ether);

    uint256 tokenAmount = _exchange.getTokenAmount(1 ether);
    console2.log("tokenAmount:", tokenAmount);

    tokenAmount = _exchange.getTokenAmount(100 ether);
    console2.log("tokenAmount:", tokenAmount);

    tokenAmount = _exchange.getTokenAmount(1000 ether);
    console2.log("tokenAmount:", tokenAmount);
  }

  function test_getEthAmount() public {
    deal(msg.sender, 1000 ether);
    deal(address(_token), msg.sender, 2000 ether);

    _token.approve(address(_exchange), 2000 ether);
    _exchange.addLiquidity{value : 1000 ether}(2000 ether);

    uint256 ethAmount = _exchange.getEthAmount(2 ether);
    console2.log("ethAmount:", ethAmount);

    ethAmount = _exchange.getEthAmount(200 ether);
    console2.log("ethAmount:", ethAmount);

    ethAmount = _exchange.getEthAmount(2000 ether);
    console2.log("ethAmount:", ethAmount);
  }

  function test_integration() public {
    address liquidityProvider = address(100);
    address user = address(200);

    deal(liquidityProvider, 100 ether);
    deal(address(_token), liquidityProvider, 200 ether);
    deal(user, 10 ether);

    vm.startPrank(liquidityProvider);
    _token.approve(address(_exchange), 200 ether);
    uint liquidity = _exchange.addLiquidity{value : 100 ether}(200 ether);
    console2.log("liquidityProvider liquidity:", liquidity);
    vm.stopPrank();

    vm.prank(user);
    _exchange.ethToTokenSwap{value : 10 ether}(18 ether);
    console2.log("user swapped token amount:", _token.balanceOf(user));

    vm.prank(liquidityProvider);
    (uint256 ethAmount, uint256 tokenAmount) = _exchange.removeLiquidity(liquidity);
    console2.log("ethAmount:", ethAmount);
    console2.log("tokenAmount:", tokenAmount);
  }

  function test_tokenToTokenSwap() public {
    Factory factory = new Factory();
    Token tokenA = new Token("TokenA", "TKNA", 10 ** 27);
    Token tokenB = new Token("TokenB", "TKNB", 10 ** 27);
    address lpProvider = address(100);
    address user = address(200);

    address exchangeA = factory.createExchange(address(tokenA));
    address exchangeB = factory.createExchange(address(tokenB));

    deal(lpProvider, 200 ether);
    deal(address(tokenA), lpProvider, 200 ether);
    deal(address(tokenB), lpProvider, 400 ether);
    deal(address(tokenA), user, 10 ether);

    vm.startPrank(lpProvider);
    tokenA.approve(exchangeA, 200 ether);
    IExchange(exchangeA).addLiquidity{value: 100 ether}(200 ether);
    tokenB.approve(exchangeB, 400 ether);
    IExchange(exchangeB).addLiquidity{value: 100 ether}(400 ether);
    vm.stopPrank();

    vm.startPrank(user);
    tokenA.approve(exchangeA, 10 ether);
    IExchange(exchangeA).tokenToTokenSwap(10 ether, 15 ether, address(tokenB));
    console2.log("user tokenB amount:", tokenB.balanceOf(user));
    vm.stopPrank();
  }
}