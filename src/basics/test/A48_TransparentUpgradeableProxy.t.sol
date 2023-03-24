// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC1967Proxy, SimpleStorageV1, SimpleStorageV2} from "./A47_UpgradeableContract.t.sol";
import {Test} from "forge-std/Test.sol";

contract TransparentUpgradeableProxy is ERC1967Proxy {

  modifier ifAdmin() {
    if (msg.sender == _getAdmin()) {
      _;
    } else {
      _fallback();
    }
  }

  constructor(
    address admin,
    address implementation,
    bytes memory data
  ) ERC1967Proxy(implementation, data) {
    _changeAdmin(admin);
  }

  function upgradeTo(address newImplementation) external override ifAdmin {
    _upgradeToAndCall(newImplementation, bytes(""), false);
  }

  function upgradeToAndCall(address newImplementation, bytes memory data) external payable override ifAdmin {
    _upgradeToAndCall(newImplementation, data, false);
  }

  function implementation() external ifAdmin returns (address) {
    return _implementation();
  }

  function getAdmin() external ifAdmin returns (address) {
    return _getAdmin();
  }

  function changeAdmin(address newAdmin) external ifAdmin {
    _changeAdmin(newAdmin);
  }
}

contract TransparentUpgradeableProxy_Test is Test {
  function testTransparentUpgradeableProxy() public {
    SimpleStorageV1 v1 = new SimpleStorageV1();
    SimpleStorageV2 v2 = new SimpleStorageV2();

    address alice = vm.addr(1);
    address bob = vm.addr(2);

    TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(alice, address(v1), bytes(""));

    proxy.changeAdmin(bob);

    vm.prank(alice);
    assertEq(proxy.getAdmin(), alice);

    vm.prank(alice);
    proxy.changeAdmin(bob);

    vm.prank(bob);
    assertEq(proxy.getAdmin(), bob);

    vm.prank(bob);
    proxy.upgradeToAndCall(address(v2), abi.encodeWithSignature("setValue(uint256)", 128));

    vm.prank(bob);
    assertEq(proxy.implementation(), address(v2));
  }
}