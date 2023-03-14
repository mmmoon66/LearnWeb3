// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract PaymentSplit {
  event PayeeAdded(address indexed payee, uint256 share);
  event PaymentReleased(address indexed to, uint256 amount);
  event PaymentReceived(address indexed from, uint256 amount);

  uint256 public totalShares;
  uint256 public totalReleased;
  mapping(address => uint256) public shares;
  mapping(address => uint256) public released;
  address[] public payees;

  receive() external payable {
    emit PaymentReceived(msg.sender, msg.value);
  }

  constructor(address[] memory payees_, uint256[] memory shares_) {
    require(payees_.length == shares_.length, "PaymentSplit: payees and shares length mismatch");
    require(payees_.length > 0, "PaymentSplit: no payees");
    for (uint256 i = 0; i < payees_.length; ++i) {
      uint256 share = shares_[i];
      address payee = payees_[i];
      require(payee != address(0), "PaymentSplit: payee zero address");
      require(shares[payee] == 0, "PaymentSplit: duplicate payee");
      require(share > 0, "PaymentSplit: invalid share");
      payees.push(payee);
      totalShares += share;
      shares[payee] = share;
      emit PayeeAdded(payee, share);
    }
  }

  function release(address account) external {
    require(shares[account] > 0, "PaymentSplit: no share");
    uint256 payment = (address(this).balance + totalReleased) * shares[account] / totalShares - released[account];
    require(payment > 0, "PaymentSplit: already released all payment");
    totalReleased += payment;
    released[account] += payment;
    (bool success,) = account.call{value : payment}("");
    require(success, "transfer failed");
    emit PaymentReleased(account, payment);
  }
}