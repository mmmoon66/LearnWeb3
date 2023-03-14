// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract PaymentSplit {
  event PayeeAdded(address indexed payee, uint256 share);
  event PaymentReleased(address indexed sender, address indexed payee, uint256 amount);
  event PaymentAdded(address indexed sender, uint256 amount);


  uint256 public totalShares;
  uint256 public totalReleased;
  mapping(address => uint256) public shares;
  mapping(address => uint256) public released;

  receive() payable {
    emit PaymentAdded(msg.sender, msg.value);
  }

  constructor(address[] memory payees, uint256[] memory shares_) {
    require(payees.length == shares_.length, "PaymentSplit: payees and shares length mismatch");
    require(payees.length > 0, "PaymentSplit: no payees");
    for (uint256 i = 0; i < payees.length; ++i) {
      uint256 share = shares_[i];
      address payee = payees[i];
      require(payee != address(0), "PaymentSplit: payee zero address");
      require(shares[payee] == 0, "PaymentSplit: duplicate payee");
      require(share > 0, "PaymentSplit: invalid share");
      totalShares += share;
      shares[payee] = share;
      emit PayeeAdded(payee, share);
    }
  }

  function release(address account) {
    require(shares[account] > 0, "PaymentSplit: no share");
    uint256 releaseAmount = address(this).balance * shares[account] / totalShares - released[account];
    require(releaseAmount > 0, "PaymentSplit: already released all payment");
    totalReleased += releaseAmount;
    released[account] += releaseAmount;
    emit PaymentReleased(msg.sender, account, releaseAmount);
  }
}