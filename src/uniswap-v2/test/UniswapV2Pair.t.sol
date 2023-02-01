// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {UniswapV2Pair} from "../UniswapV2Pair.sol";
import {MintableERC20} from "../MintableERC20.sol";
import {UniswapV2Library} from "../UniswapV2Library.sol";

contract UniswapV2Pair_Test is Test {
  MintableERC20 private _tokenA;
  MintableERC20 private _tokenB;
  UniswapV2Pair private _pair;

  function setUp() public {
    _tokenA = new MintableERC20("Mintable Token A", "TKNA", 18);
    _tokenB = new MintableERC20("Mintable Token B", "TKNB", 18);
    _pair = new UniswapV2Pair();
    _pair.initialize(address(_tokenA), address(_tokenB));

    _tokenA.mint(address(this), 10 ether);
    _tokenB.mint(address(this), 10 ether);
  }

  function testMintBootstrap() public {
    _tokenA.transfer(address(_pair), 1 ether);
    _tokenB.transfer(address(_pair), 1 ether);

    uint256 liquidity = _pair.mint(address(this));
    assertEq(liquidity, 1 ether - 1000);
    _assertReserves(1 ether, 1 ether);
    assertEq(_pair.totalSupply(), 1 ether);
  }

  function testMintWhenTheresLiquidity() public {
    _tokenA.transfer(address(_pair), 1 ether);
    _tokenB.transfer(address(_pair), 1 ether);
    // +1 LP
    _pair.mint(address(this));

    _tokenA.transfer(address(_pair), 2 ether);
    _tokenB.transfer(address(_pair), 2 ether);
    // +2 LP
    _pair.mint(address(this));

    assertEq(_pair.balanceOf(address(this)), 3 ether - 1000);
    _assertReserves(3 ether, 3 ether);
    assertEq(_pair.totalSupply(), 3 ether);
  }

  function testMintUnbalanced() public {
    _tokenA.transfer(address(_pair), 1 ether);
    _tokenB.transfer(address(_pair), 1 ether);
    // +1 LP
    _pair.mint(address(this));

    _tokenA.transfer(address(_pair), 1 ether);
    _tokenB.transfer(address(_pair), 2 ether);
    // +1 LP
    _pair.mint(address(this));

    assertEq(_pair.balanceOf(address(this)), 2 ether - 1000);
    _assertReserves(2 ether, 3 ether);
    assertEq(_pair.totalSupply(), 2 ether);
  }

  function testBurn() public {
    _tokenA.transfer(address(_pair), 1 ether);
    _tokenB.transfer(address(_pair), 1 ether);
    _pair.mint(address(this));
    // burn all LP tokens (1 ether - 1000)
    _pair.transfer(address(_pair), _pair.balanceOf(address(this)));
    _pair.burn(address(this));

    _assertReserves(1000, 1000);
    assertEq(_pair.totalSupply(), 1000);
    assertEq(_tokenA.balanceOf(address(this)), 10 ether - 1000);
    assertEq(_tokenB.balanceOf(address(this)), 10 ether - 1000);
  }

  function testBurnUnbalanced() public {
    _tokenA.transfer(address(_pair), 1 ether);
    _tokenB.transfer(address(_pair), 4 ether);
    _pair.mint(address(this));
    // burn all LP tokens (2 ether - 1000)
    _pair.transfer(address(_pair), _pair.balanceOf(address(this)));
    _pair.burn(address(this));

    // (2 ether - 1000) / 2 ether = amountA / 1 ether = amountB / 4 ether
    // amountA = 1 ether - 500
    // amountB = 4 ether - 2000
    _assertReserves(500, 2000);
    assertEq(_pair.totalSupply(), 1000);
    assertEq(_tokenA.balanceOf(address(this)), 10 ether - 500);
    assertEq(_tokenB.balanceOf(address(this)), 10 ether - 2000);
  }

  function testBurnWhenTheresLiquidity() public {
    // address(this) provides liquidity
    _tokenA.transfer(address(_pair), 1 ether);
    _tokenB.transfer(address(_pair), 1 ether);
    _pair.mint(address(this));

    // alice provides liquidity
    address alice = address(100);
    deal(address(_tokenA), alice, 2 ether);
    deal(address(_tokenB), alice, 2 ether);
    vm.startPrank(alice);
    _tokenA.transfer(address(_pair), 2 ether);
    _tokenB.transfer(address(_pair), 2 ether);
    vm.stopPrank();
    _pair.mint(alice);

    assertEq(_pair.balanceOf(alice), 2 ether);
    _assertReserves(3 ether, 3 ether);
    assertEq(_pair.totalSupply(), 3 ether);

    // alice removes liquidity
    vm.prank(alice);
    _pair.transfer(address(_pair), 1 ether);
    _pair.burn(alice);
    assertEq(_pair.balanceOf(alice), 1 ether);
    assertEq(_tokenA.balanceOf(alice), 1 ether);
    assertEq(_tokenB.balanceOf(alice), 1 ether);
    _assertReserves(2 ether, 2 ether);
    assertEq(_pair.totalSupply(), 2 ether);
  }

  function testBurnUnbalancedWhenTheresLiquidity() public {
    // address(this) provides liquidity
    _tokenA.transfer(address(_pair), 1 ether);
    _tokenB.transfer(address(_pair), 1 ether);
    _pair.mint(address(this));

    // alice provides unbalanced liquidity
    address alice = address(100);
    deal(address(_tokenA), alice, 1 ether);
    deal(address(_tokenB), alice, 2 ether);
    vm.startPrank(alice);
    _tokenA.transfer(address(_pair), 1 ether);
    _tokenB.transfer(address(_pair), 2 ether);
    vm.stopPrank();
    _pair.mint(alice);

    assertEq(_pair.balanceOf(alice), 1 ether);
    _assertReserves(2 ether, 3 ether);
    assertEq(_pair.totalSupply(), 2 ether);

    // alice removes liquidity
    vm.prank(alice);
    _pair.transfer(address(_pair), 1 ether);
    _pair.burn(alice);
    assertEq(_pair.balanceOf(alice), 0 ether);
    assertEq(_tokenA.balanceOf(alice), 1 ether);
    assertEq(_tokenB.balanceOf(alice), 1.5 ether);
    _assertReserves(1 ether, 1.5 ether);
    assertEq(_pair.totalSupply(), 1 ether);
  }

  function testSwapBasicScenario() public {
    _tokenA.transfer(address(_pair), 1 ether);
    _tokenB.transfer(address(_pair), 2 ether);
    _pair.mint(address(this));

    uint256 amountAIn = 0.1 ether;
    uint256 amountBOut = UniswapV2Library.getAmountOut(amountAIn, 1 ether, 2 ether);
    _tokenA.transfer(address(_pair), amountAIn);
    _pair.swap(0, amountBOut, address(this), "");

    assertEq(
      _tokenA.balanceOf(address(this)),
      10 ether - 1 ether - 0.1 ether,
      "unexpected tokenA balance"
    );
    assertEq(
      _tokenB.balanceOf(address(this)),
      10 ether - 2 ether + amountBOut,
      "unexpected tokenB balance"
    );
    _assertReserves(1 ether + amountAIn, 2 ether - amountBOut);
  }

  function testSwapBasicScenarioReserveDirection() public {
    _tokenA.transfer(address(_pair), 1 ether);
    _tokenB.transfer(address(_pair), 2 ether);
    _pair.mint(address(this));

    uint256 amountBIn = 0.2 ether;
    uint256 amountAOut = UniswapV2Library.getAmountOut(amountBIn, 2 ether, 1 ether);
    _tokenB.transfer(address(_pair), amountBIn);
    _pair.swap(amountAOut, 0, address(this), "");

    assertEq(_tokenA.balanceOf(address(this)), 10 ether - 1 ether + amountAOut, "unexpected tokenA balance");
    assertEq(_tokenB.balanceOf(address(this)), 10 ether - 2 ether - amountBIn, "unexpected tokenB balance");
    _assertReserves(1 ether - amountAOut, 2 ether + amountBIn);
  }

  function testSwapBidirectional() public {
    _tokenA.transfer(address(_pair), 1 ether);
    _tokenB.transfer(address(_pair), 2 ether);
    _pair.mint(address(this));

    uint112 reserveA = 1 ether;
    uint112 reserveB = 2 ether;
    uint256 amountAIn = 0.1 ether;
    uint256 amountBIn = 0.2 ether;
    uint256 amountBOut = UniswapV2Library.getAmountOut(amountAIn, reserveA, reserveB);
    uint256 amountAOut = UniswapV2Library.getAmountOut(amountBIn, reserveB, reserveA);
    _tokenA.transfer(address(_pair), amountAIn);
    _tokenB.transfer(address(_pair), amountBIn);
    _pair.swap(amountAOut, amountBOut, address(this), "");

    assertEq(_tokenA.balanceOf(address(this)), 10 ether - 1 ether - amountAIn + amountAOut, "unexpected tokenA balance");
    assertEq(_tokenB.balanceOf(address(this)), 10 ether - 2 ether - amountBIn + amountBOut, "unexpected tokenB balance");
    _assertReserves(reserveA + amountAIn - amountAOut, reserveB + amountBIn - amountBOut);
  }

  function testSwapInsufficientAmount() public {
    _tokenA.transfer(address(_pair), 1 ether);
    _tokenB.transfer(address(_pair), 2 ether);
    _pair.mint(address(this));

    vm.expectRevert(_encodeError("InsufficientAmount()"));
    _pair.swap(0, 0, address(this), "");
  }

  function testSwapInsufficientLiquidity() public {
    _tokenA.transfer(address(_pair), 1 ether);
    _tokenB.transfer(address(_pair), 2 ether);
    _pair.mint(address(this));

    vm.expectRevert(_encodeError("InsufficientLiquidity()"));
    _pair.swap(1.1 ether, 0,  address(this), "");

    vm.expectRevert(_encodeError("InsufficientLiquidity()"));
    _pair.swap(0, 2.2 ether,  address(this), "");
  }

  function testSwapUnderpriced() public {
    _tokenA.transfer(address(_pair), 1 ether);
    _tokenB.transfer(address(_pair), 2 ether);
    _pair.mint(address(this));

    _tokenA.transfer(address(_pair), 0.1 ether);
    _pair.swap(0, 0.05 ether, address(this), "");

    assertEq(_tokenA.balanceOf(address(this)), 10 ether - 1 ether - 0.1 ether, "unexpected tokenA balance");
    assertEq(_tokenB.balanceOf(address(this)), 10 ether - 2 ether + 0.05 ether, "unexpected tokenB balance");
    _assertReserves(1 ether + 0.1 ether, 2 ether - 0.05 ether);
  }

  function testSwapOverpriced() public {
    _tokenA.transfer(address(_pair), 1 ether);
    _tokenB.transfer(address(_pair), 2 ether);
    _pair.mint(address(this));

    _tokenA.transfer(address(_pair), 0.1 ether);
    vm.expectRevert(_encodeError("InvalidK()"));
    _pair.swap(0, 0.4 ether, address(this), "");

    assertEq(_tokenA.balanceOf(address(this)), 10 ether - 1 ether - 0.1 ether, "unexpected tokenA balance");
    assertEq(_tokenB.balanceOf(address(this)), 10 ether - 2 ether, "unexpected tokenB balance");
    _assertReserves(1 ether, 2 ether);
  }

  function _encodeError(string memory signature) private pure returns (bytes memory encoded) {
    encoded = abi.encodeWithSignature(signature);
  }

  function _assertReserves(uint256 expectReserveA, uint256 expectReserveB) private {
    (uint112 reserve0, uint112 reserve1,) = UniswapV2Pair(address(_pair)).getReserves();
    assertEq(uint256(reserve0), expectReserveA, "unexpected reserveA");
    assertEq(uint256(reserve1), expectReserveB, "unexpected reserveB");
  }
}