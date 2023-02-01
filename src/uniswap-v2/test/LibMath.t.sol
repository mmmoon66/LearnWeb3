// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {LibMath} from "../libraries/LibMath.sol";

contract LibMath_Test is Test {
  function test_sqrt() public {
    assertEq(LibMath.sqrt(0), 0);
    assertEq(LibMath.sqrt(1), 1);
    assertEq(LibMath.sqrt(2), 1);
    assertEq(LibMath.sqrt(3), 1);
    assertEq(LibMath.sqrt(4), 2);
    assertEq(LibMath.sqrt(5), 2);
    assertEq(LibMath.sqrt(6), 2);
    assertEq(LibMath.sqrt(7), 2);
    assertEq(LibMath.sqrt(8), 2);
    assertEq(LibMath.sqrt(9), 3);
    assertEq(LibMath.sqrt(10), 3);
  }
}