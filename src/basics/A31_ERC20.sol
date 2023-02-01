// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function balanceOf(address account) external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function transfer(address to, uint256 amount) external returns (bool);

  function transferFrom(address from, address to, uint256 amount) external returns (bool);

  function approve(address spender, uint256 amount) external returns (bool);
}

contract ERC20 {
  event Transfer(address indexed from, address indexed to, uint256 amount);
  event Approval(address indexed owner, address indexed spender, uint256 amount);

  string public name;
  string public symbol;
  uint8 public immutable decimals;

  mapping(address => uint256) public balanceOf;
  uint256 public totalSupply;

  // owner => spender => amount
  mapping(address => mapping(address => uint256)) allowance;

  constructor(string memory name_, string memory symbol_, uint8 decimals_) {
    name = name_;
    symbol = symbol_;
    decimals = decimals_;
  }

  function transfer(address to, uint256 amount) external returns (bool) {
    balanceOf[msg.sender] -= amount;
    unchecked { balanceOf[to] += amount; }
    emit Transfer(msg.sender, to, amount);
    return true;
  }

  function transferFrom(address from, address to, uint256 amount) external returns (bool) {
    uint256 allowed = allowance[from][msg.sender];
    if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;
    balanceOf[from] -= amount;
    unchecked { balanceOf[to] += amount; }
    emit Transfer(from, to, amount);
    return true;
  }

  function approve(address spender, uint256 amount) external returns (bool) {
    allowance[msg.sender][spender] = amount;
    emit Approval(msg.sender, spender, amount);
    return true;
  }

  function _mint(address to, uint256 amount) internal virtual {
    totalSupply += amount;
    unchecked { balanceOf[to] += amount; }
    emit Transfer(address(0), to, amount);
  }

  function _burn(address from, uint256 amount) internal virtual {
    balanceOf[from] -= amount;
    unchecked { totalSupply -= amount; }
    emit Transfer(from, address(0), amount);
  }
}