// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/*
forge create src/taiko/L2Bank.sol:L2Bank --private-key=$guoliang_private_key --legacy
Deployer: 0x65047fbb4be8fC1DE7dB83A7EfA3865d10952411
Deployed to: 0x3E6c9887385Ec79B413b809feA72F7C8117D7C02
Transaction hash: 0x14ba0c32b79e198f371ed874d1b535aa7d20dac4b95848ed472a36388a4915ec
*/
contract L2Bank {
  event Deposit(address indexed sender, address indexed to, uint256 amount);
  event Withdraw(address indexed sender, address indexed to, uint256 amount);

  mapping(address => uint256) private _balances;

  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  function deposit(address account) external payable {
    require(account != address(0), "invalid account");
    require(msg.value > 0, "zero value");
    _balances[account] += msg.value;
    emit Deposit(msg.sender, account, msg.value);
  }

  function withdraw(address account) external {
    uint256 balance = _balances[account];
    require(balance > 0, "zero balance");
    _balances[account] = 0;
    (bool success,) = account.call{value : balance}("");
    require(success, "withdraw failed");
    emit Withdraw(msg.sender, account, balance);
  }

}