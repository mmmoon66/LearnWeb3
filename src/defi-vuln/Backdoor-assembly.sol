// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

// An attacker can manipulate smart contracts as a backdoor by writing inline assembly. Any sensitive parameters can be changed at any time.

contract LotteryGame {
  uint256 public prize = 1000;
  address public winner;
  address public admin = msg.sender;

  modifier safeCheck() {
//    console.log("safeCheck, msg.sender:", msg.sender);
//    console.log("safeCheck, referee:", referee());
    if (msg.sender == referee()) {
      _;
    } else {
      getWinner();
    }
  }

  function referee() public view returns (address ref) {
    assembly {
      ref := sload(2)
    }
//    console.log("referee:", ref);
  }

  function pickWinner(address random) public safeCheck {
    assembly {
      sstore(1, random)
    }
  }

  function getWinner() public view returns (address) {
    console.log("getWinner:", winner);
    return winner;
  }
}

contract BackdoorAssembly is Test {
  LotteryGame private game;
  address private alice = address(128);
  address private bob = address(256);

  function setUp() public {
    game = new LotteryGame();
  }

  function test_backdoor() public {
    console.log("Alice perform pickWinner, she will absolutely not be a winner");
    vm.prank(alice);
    game.pickWinner(alice);

    console.log("Now, admin set the winner to drain out the prize");
    game.pickWinner(bob);
    console.log("Admin manipulated winner:", game.getWinner());
  }
}