// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";

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

library Address {
  function isContract(address account) internal view returns (bool) {
    return account.code.length > 0;
  }

  function functionDelegateCall(address target, bytes memory data) internal {
    (bool success, bytes memory returnData) = target.delegatecall(data);
  }
}

abstract contract Proxy {
  fallback() external payable virtual {
    _fallback();
  }

  receive() external payable virtual {
    _fallback();
  }

  function _fallback() internal virtual {
    _beforeFallback();
    _delegate(_implementation());
  }

  function _beforeFallback() internal virtual {}

  function _delegate(address implementation) internal virtual {
    assembly {
      calldatacopy(0, 0, calldatasize())

    // 0 on error, 1 on success
      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

      returndatacopy(0, 0, returndatasize())

      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return (0, returndatasize())
      }
    }
  }

  function _implementation() internal view virtual returns (address);
}

abstract contract ERC1967Upgrade {
  event ImplementationUpgraded(address indexed newImplementation);

  bytes32 private immutable _IMPLEMENTATION_SLOT = bytes32(uint256(keccak256(abi.encodePacked("eip1967.proxy.implementation"))) - 1);

  function _setImplementation(address implementation) internal virtual {
    require(Address.isContract(implementation), "ERC1967Upgrade: implementation is not a contract");
    StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = implementation;
  }

  function _getImplementation() internal view virtual returns (address) {
    return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
  }

  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit ImplementationUpgraded(newImplementation);
  }

  function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
    _upgradeTo(newImplementation);
    if (data.length > 0 || forceCall) {
      Address.functionDelegateCall(newImplementation, data);
    }
  }
}

contract ERC1967Proxy is Proxy, ERC1967Upgrade {
  constructor(
    address implementation,
    bytes memory data
  ) payable {
    _upgradeToAndCall(implementation, data, false);
  }

  function _implementation() internal view override returns (address) {
    return ERC1967Upgrade._getImplementation();
  }

  function upgradeTo(address newImplementation) external {
    ERC1967Upgrade._upgradeTo(newImplementation);
  }

  function upgradeToAndCall(address newImplementation, bytes memory data) external {
    ERC1967Upgrade._upgradeToAndCall(newImplementation, data, false);
  }
}

contract SimpleStorageV1 {
  uint256 private _value;

  function setValue(uint256 value) external {
    _value = value;
  }

  function getValue() external view returns (uint256) {
    return _value;
  }
}

contract SimpleStorageV2 {
  event ValueChanged(uint256 oldValue, uint256 newValue);

  uint256 private _value;

  function setValue(uint256 value) external {
    uint256 oldValue = _value;
    _value = value;
    emit ValueChanged(oldValue, value);
  }

  function getValue() external view returns (uint256) {
    return _value;
  }
}

contract ERC1967Proxy_Test is Test {
  function testERC1967Proxy() public {
    SimpleStorageV1 v1 = new SimpleStorageV1();
    SimpleStorageV2 v2 = new SimpleStorageV2();

    ERC1967Proxy proxy = new ERC1967Proxy(address(v1), abi.encodeWithSignature("setValue(uint256)", 2));
    (bool success, bytes memory returnData) = address(proxy).call(abi.encodeWithSignature("getValue()"));
    assert(success);
    uint256 value = abi.decode(returnData, (uint256));
    assertEq(value, 2);

    proxy.upgradeToAndCall(address(v2), abi.encodeWithSignature("setValue(uint256)", 4));
    (success, returnData) = address(proxy).call(abi.encodeWithSignature("getValue()"));
    assert(success);
    value = abi.decode(returnData, (uint256));
    assertEq(value, 4);
  }

  function testSelectorClash() public {
    SimpleStorageV1 v1 = new SimpleStorageV1();
    SimpleStorageV2 v2 = new SimpleStorageV2();

    ERC1967Proxy proxy = new ERC1967Proxy(address(v1), bytes(""));
    (bool success, bytes memory returnData) = address(proxy).call(abi.encodeWithSignature("upgradeTo(address)", address(v2)));
    assert(success);
    console2.logBytes(returnData);
  }
}