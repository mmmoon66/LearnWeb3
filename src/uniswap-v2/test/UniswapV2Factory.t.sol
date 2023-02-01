// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {UniswapV2Factory} from "../UniswapV2Factory.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {UniswapV2Pair} from "../UniswapV2Pair.sol";

contract Token is ERC20 {
  constructor(string memory name, string memory symbol) ERC20(name, symbol, 18) {
    _mint(msg.sender, 10 ** 9 * 1 ether);
  }
}

contract UniswapV2Factory_Test is Test {
  address private _tokenA;
  address private _tokenB;
  UniswapV2Factory private _factory;

  function setUp() public {
    _tokenA = address(new Token("TokenA", "TKNA"));
    _tokenB = address(new Token("TokenB", "TKNB"));
    _factory = new UniswapV2Factory();
  }

  function testCreatePair() public {
    address pairAddr = _factory.createPair(_tokenA, _tokenB);
    UniswapV2Pair pair = UniswapV2Pair(pairAddr);
    (address token0, address token1) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);
    assertEq(token0, pair.token0());
    assertEq(token1, pair.token1());
  }

  function testCreatePairIdenticalAddresses() public {
    vm.expectRevert(_encodeError("IdenticalAddresses()"));
    _factory.createPair(_tokenA, _tokenA);
  }

  function testCreatePairZeroAddress() public {
    vm.expectRevert(_encodeError("ZeroAddress()"));
    _factory.createPair(_tokenA, address(0));

    vm.expectRevert(_encodeError("ZeroAddress()"));
    _factory.createPair(address(0), _tokenA);
  }

  function testCreatePairExists() public {
    _factory.createPair(_tokenA, _tokenB);

    vm.expectRevert(_encodeError("PairExists()"));
    _factory.createPair(_tokenA, _tokenB);
  }

  function _encodeError(string memory signature) private pure returns (bytes memory) {
    return abi.encodeWithSignature(signature);
  }
}