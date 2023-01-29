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
  uint8 public decimals;

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
    require(balanceOf[msg.sender] >= amount, "ERC20: insufficient balance");
    balanceOf[msg.sender] -= amount;
    balanceOf[to] += amount;
    return true;
  }

  function transferFrom(address from, address to, uint256 amount) external returns (bool) {
    require(allowance[from][msg.sender] >= amount || from == msg.sender, "ERC20: insufficient allowance or msg.sender not owner");
    require(balanceOf[from] >= amount, "ERC20: insufficient balance");
    balanceOf[from] -= amount;
    balanceOf[to] += amount;
    if (from != msg.sender) allowance[from][msg.sender] -= amount;
    return true;
  }

  function approve(address spender, uint256 amount) external returns (bool) {
    require(spender != msg.sender, "ERC20: invalid spender");
    allowance[msg.sender][spender] = amount;
    emit Approval(msg.sender, spender, amount);
    return true;
  }

  function _mint(address to, uint256 amount) internal returns (bool) {
    balanceOf[to] += amount;
    totalSupply += amount;
    return true;
  }

  function _burn(address from, uint256 amount) internal returns (bool) {
    require(balanceOf[from] >= amount, "ERC20: insufficient balance");
    balanceOf[from] -= amount;
    totalSupply -= amount;
    return true;
  }
}