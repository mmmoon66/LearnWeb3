// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";

abstract contract Proxy {

  fallback() external payable virtual {
    _fallback();
  }

  receive() external payable virtual {
    _fallback();
  }

  function _delegate(address implementation) internal virtual {
    assembly {
    // 将msg.data全部拷贝到mem的0索引位置处
      calldatacopy(0, 0, calldatasize())

    // 调用implementation
    // result: 0 on error, 1 on success
      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

    // 将returndata拷贝至mem
      returndatacopy(0, 0, returndatasize())

    // 根据result判断调用是否成功
      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return (0, returndatasize())
      }
    }
  }

  function _fallback() internal virtual {
    _beforeFallback();
    _delegate(_implementation());
  }

  function _beforeFallback() internal virtual {}

  function _implementation() internal view virtual returns (address);
}

library StorageSlot {
  struct AddressSlot {
    address value;
  }

  function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
    assembly {
      r.slot := slot
    }
  }
}

contract SimpleStorageImpl {
  uint256 private _value;

  function setValue(uint256 value) external {
    _value = value;
  }

  function getValue() external view returns (uint256) {
    return _value;
  }
}

contract SimpleStorageProxy is Proxy {

  //  bytes32 private immutable IMPLEMENTATION_SLOT = bytes32(uint256(keccak256(bytes("eip1967.proxy.implementation"))) - 1);
  // immutable 一定不能省略，否则impl中 state variable 的 slot 对应不上
  bytes32 private immutable IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  constructor(address implementation) {
    StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value = implementation;
  }

  function _implementation() internal view override returns (address impl) {
    return StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value;
  }
}

contract ProxyContract_Test is Test {
  function testProxyContract() public {
    SimpleStorageImpl impl = new SimpleStorageImpl();
    SimpleStorageProxy proxy = new SimpleStorageProxy(address(impl));

    (bool success1,) = address(proxy).call(abi.encodeWithSignature("setValue(uint256)", 8));
    assert(success1);

    (bool success2, bytes memory returnData) = address(proxy).call(abi.encodeWithSignature("getValue()"));
    assert(success2);
    uint256 value = abi.decode(returnData, (uint256));
    assertEq(value, 8);
  }
}