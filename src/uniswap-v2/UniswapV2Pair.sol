// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {LibMath} from "./libraries/LibMath.sol";
import {LibUQ112x112} from "./libraries/LibUQ112x112.sol";
import {IUniswapV2Callee} from "./UniswapV2Callee.sol";
import {console2} from "forge-std/Test.sol";

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);

  function transfer(address to, uint256 amount) external returns (bool);

  function transferFrom(address from, address to, uint256 amount) external returns (bool);
}


interface IUniswapV2Pair {
  function getReserves() external view returns (uint112, uint112, uint32);

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;
}


contract UniswapV2Pair is IUniswapV2Pair, ERC20 {

  using LibUQ112x112 for uint224;

  error AlreadyInitialized();
  error InsufficientLiquidityMinted();
  error BalanceOverflow();
  error InsufficientLiquidityBurned();
  error InsufficientAmount();
  error InvalidK();
  error InsufficientLiquidity();
  error SafeTransferFailed();

  event Mint(address indexed to, uint256 amount0, uint256 amount1);
  event Sync(uint112 reserve0, uint112 reserve1);
  event Burn(address indexed to, uint256 amount0, uint256 amount1);
  event Swap(address indexed to, uint256 amount0Out, uint256 amount1Out);

  uint256 constant MINIMUM_LIQUIDITY = 1000;
  address public token0;
  address public token1;

  uint112 private _reserve0;
  uint112 private _reserve1;
  uint32 private _blockTimestampLast;

  uint256 public price0CumulativeLast;
  uint256 public price1CumulativeLast;

  bool private _isEntered;

  modifier nonReentrant {
    require(!_isEntered);
    _isEntered = true;
    _;
    _isEntered = false;
  }

  constructor() ERC20("UniswapV2 Pair", "UNIV2", 18) {}

  function initialize(address token0_, address token1_) external {
    if (token0 != address(0) || token1 != address(0)) {
      revert AlreadyInitialized();
    }
    token0 = token0_;
    token1 = token1_;
  }

  function getReserves() public view returns (uint112, uint112, uint32) {
    return (_reserve0, _reserve1, _blockTimestampLast);
  }

  function mint(address to) public returns (uint256 liquidity) {
    (uint112 reserve0, uint112 reserve1,) = getReserves();
    uint256 balance0 = IERC20(token0).balanceOf(address(this));
    uint256 balance1 = IERC20(token1).balanceOf(address(this));
    uint256 amount0 = balance0 - reserve0;
    uint256 amount1 = balance1 - reserve1;

    if (totalSupply == 0) {
      liquidity = LibMath.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
      _mint(address(0), MINIMUM_LIQUIDITY);
    } else {
      liquidity = LibMath.min(
        amount0 * totalSupply / _reserve0,
        amount1 * totalSupply / _reserve1
      );
    }
    if (liquidity <= 0) revert InsufficientLiquidityMinted();
    _mint(to, liquidity);
    _update(balance0, balance1, reserve0, reserve1);
    emit Mint(to, amount0, amount1);
  }

  function burn(address to) public returns (uint256 amount0, uint256 amount1) {
    uint256 balance0 = IERC20(token0).balanceOf(address(this));
    uint256 balance1 = IERC20(token1).balanceOf(address(this));
    uint256 liquidity = balanceOf[address(this)];
    amount0 = liquidity * balance0 / totalSupply;
    amount1 = liquidity * balance1 / totalSupply;
    if (amount0 == 0 || amount1 == 0) revert InsufficientLiquidityBurned();
    _burn(address(this), liquidity);
    _safeTransfer(token0, to, amount0);
    _safeTransfer(token1, to, amount1);
    balance0 = IERC20(token0).balanceOf(address(this));
    balance1 = IERC20(token1).balanceOf(address(this));
    (uint112 reserve0, uint112 reserve1,) = getReserves();
    _update(balance0, balance1, reserve0, reserve1);
    emit Burn(to, amount0, amount1);
  }

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) public nonReentrant {
    if (amount0Out == 0 && amount1Out == 0) revert InsufficientAmount();
    (uint112 reserve0, uint112 reserve1,) = getReserves();
    if (amount0Out >= reserve0 || amount1Out >= reserve1) revert InsufficientLiquidity();
    if (amount0Out > 0) _safeTransfer(token0, to, amount0Out);
    if (amount1Out > 0) _safeTransfer(token1, to, amount1Out);
    if (data.length > 0) {
      IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
    }
    uint256 balance0 = IERC20(token0).balanceOf(address(this));
    uint256 balance1 = IERC20(token1).balanceOf(address(this));
    uint256 amount0In = balance0 > reserve0 - amount0Out ? balance0 - (reserve0 - amount0Out) : 0;
    uint256 amount1In = balance1 > reserve1 - amount1Out ? balance1 - (reserve1 - amount1Out) : 0;
    uint256 balance0Adjusted = 1000 * balance0 - 3 * amount0In;
    uint256 balance1Adjusted = 1000 * balance1 - 3 * amount1In;
    if (balance0Adjusted * balance1Adjusted < uint256(reserve0) * uint256(reserve1) * (1000 ** 2)) revert InvalidK();
    _update(balance0, balance1, reserve0, reserve1);
    emit Swap(to, amount0Out, amount1Out);
  }

  function sync() public {
    (uint112 reserve0, uint112 reserve1,) = getReserves();
    uint256 balance0 = IERC20(token0).balanceOf(address(this));
    uint256 balance1 = IERC20(token1).balanceOf(address(this));
    _update(balance0, balance1, reserve0, reserve1);
  }

  function _update(uint256 balance0, uint256 balance1, uint112 reserve0, uint112 reserve1) private {
    if (balance0 > type(uint112).max || balance1 > type(uint112).max) {
      revert BalanceOverflow();
    }
  unchecked {
    uint32 timeElapsed = uint32(block.timestamp) - _blockTimestampLast;
    if (timeElapsed > 0 && reserve0 > 0 && reserve1 > 0) {
      price0CumulativeLast += uint256(LibUQ112x112.encode(reserve1).uqdiv(reserve0)) * timeElapsed;
      price1CumulativeLast += uint256(LibUQ112x112.encode(reserve0).uqdiv(reserve1)) * timeElapsed;
    }
  }
    _reserve0 = uint112(balance0);
    _reserve1 = uint112(balance1);
    _blockTimestampLast = uint32(block.timestamp);
    emit Sync(_reserve0, _reserve1);
  }

  function _safeTransfer(address token, address to, uint256 amount) private {
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSignature(
        "transfer(address,uint256)",
        to,
        amount
      )
    );
    if (!success || !abi.decode(data, (bool))) {
      revert SafeTransferFailed();
    }
  }
}