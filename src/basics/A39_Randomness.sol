// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {VRFConsumerBase} from "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {console} from "forge-std/Test.sol";

address constant LINK_TOKEN = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

contract RandomNumberConsumer is VRFConsumerBase {
  // https://docs.chain.link/vrf/v1/supported-networks
  // Ethereum Mainnet
  // VRFCoordinator: 0x271682DEB8C4E0901D1a1550aD2e64D568E69909
  // LINK token: 0x514910771AF9Ca656af840dff83E8264EcF986CA
  address public constant VRF_COORDINATOR = 0xf0d54349aDdcf704F77AE15b96510dEA15cb7952;
  bytes32 public constant KEY_HASH = hex"AA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445";
  uint256 public constant FEE = 2 * 10 ** 18;

  error NOT_ENOUGH_LINK();

  uint256 public randomNumber;

  constructor() VRFConsumerBase(VRF_COORDINATOR, LINK_TOKEN) {}

  function getRandomNumber() external returns (bytes32 requestId) {
    if (IERC20(LINK_TOKEN).balanceOf(address(this)) < FEE) revert NOT_ENOUGH_LINK();
    requestId = requestRandomness(KEY_HASH, FEE);
    console.logBytes32(requestId);
  }

  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
    console.logBytes32(requestId);
    console.log("fulfillRandomness, randomness:", randomness);
    randomNumber = randomness;
  }
}