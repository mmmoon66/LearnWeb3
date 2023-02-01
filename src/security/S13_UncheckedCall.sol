// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

contract UncheckedBank {
  mapping(address => uint256) public deposits;

  function deposit() external payable {
    deposits[msg.sender] += msg.value;
  }

  function withdraw() external {
    require(deposits[msg.sender] > 0, "insufficient fund");
    // uncheck the call result, msg.sender is a contract which does not implement receive / fallback
    // so this call will fail
    msg.sender.call{value : deposits[msg.sender]}("");
    deposits[msg.sender] = 0;
  }

  function balance() external view returns (uint256) {
    return address(this).balance;
  }
}

contract Depositor {
  UncheckedBank private _bank;

  constructor(address bankAddr) {
    _bank = UncheckedBank(bankAddr);
  }

  function deposit() external payable {
    _bank.deposit{value : msg.value}();
  }

  function withdraw() external {
    _bank.withdraw();
    (bool success, ) = msg.sender.call{value : address(this).balance}("");
    require(success, "withdraw failed");
  }
}