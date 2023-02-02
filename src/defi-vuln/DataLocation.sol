// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";

// Data location - storage vs memory :
//Incorrect use of storage slot and memory to save variable state can easily cause contracts to use values not updated for calculations. REF1, REF2
contract DataLocation is Test {
  function testDataLocation() public {
    UserInfoManager manager = new UserInfoManager();
    address alice = vm.addr(1);
    address bob = vm.addr(2);

    manager.updateUserBalance(alice, 100);
    (, uint256 balanceOfAlice) = manager.userInfo(alice);
    assertEq(balanceOfAlice, 0);

    manager.fixedUpdateUserBalance(bob, 200);
    (, uint256 balanceOfBob) = manager.userInfo(bob);
    assertEq(balanceOfBob, 200);
  }
}

contract UserInfoManager {
  struct UserInfo {
    uint256 id;
    uint256 balance;
  }
  mapping(address => UserInfo) public userInfo;

  function updateUserBalance(address addr, uint256 balance) external view {
    UserInfo memory info = userInfo[addr];
    info.balance = balance;
  }

  function fixedUpdateUserBalance(address addr, uint256 balance) external {
    UserInfo storage info = userInfo[addr];
    info.balance = balance;
  }
}
