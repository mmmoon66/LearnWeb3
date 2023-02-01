// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {console} from "forge-std/Test.sol";

interface IUniswapV2Factory {
  function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Pair {
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract OUSD is ERC20 {

  address private constant FACTORY_V2 = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
  address private constant BUSD = 0x4Fabb145d64652a948d72533023f6E7A623C7C53; // token0
  address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // token1
  address private immutable PAIR;

  constructor() ERC20("Oracle USD", "oUSD") {
    PAIR = IUniswapV2Factory(FACTORY_V2).getPair(BUSD, WETH);
  }

  function getEthPrice() public view returns (uint256) {
    (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(PAIR).getReserves();
//    console.log("reserve0:", uint256(reserve0));
//    console.log("reserve1:", uint256(reserve1));
    return reserve0 / reserve1;
  }

  function swap() public payable returns (uint256 amountOut) {
    require(msg.value > 0, "insufficient eth value");
    amountOut = getEthPrice() * msg.value;
    _mint(msg.sender, amountOut);
  }
}