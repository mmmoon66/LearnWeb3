// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {RandomNumberConsumer, LINK_TOKEN} from "../A39_Randomness.sol";

contract RandomNumberConsumer_Test is Test {
  RandomNumberConsumer public consumer;

  function setUp() public {
    string memory rpcUrl = vm.envString("mainnet");
    console.log("rpcUrl:", rpcUrl);
    uint256 blockNumber = 16695433;
    uint256 forkId = vm.createSelectFork(rpcUrl, blockNumber);
    console.log("forkId:", forkId);
    consumer = new RandomNumberConsumer();
  }

  function testRandomNumber() public {
    deal(LINK_TOKEN, address(consumer), 100 ether);
    consumer.getRandomNumber();
  }
}