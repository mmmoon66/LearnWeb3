// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Test, console2} from "forge-std/Test.sol";

contract MultiSigWallet {
  event ExecutionSuccess(bytes32 indexed dataHash);
  event ExecutionFailure(bytes32 indexed dataHash);

  uint8 private immutable _threshold;
  mapping(address => bool) private _isOwner;
  address[] private _owners;
  uint256 private _nonce;

  receive() external payable {}

  constructor(address[] memory owners, uint8 threshold) {
    require(owners.length > 0, "owners zero length");
    for (uint256 i = 0; i < owners.length; ++i) {
      address owner = owners[i];
      require(owner != address(0), "owner zero address");
      require(!_isOwner[owner], "duplicate owner");
      _isOwner[owner] = true;
      _owners.push(owner);
    }
    require(threshold > 0, "zero threshold");
    require(threshold <= owners.length, "threshold should be equal or smaller than owners length");
    _threshold = threshold;
  }

  function executeTransaction(
    address target,
    uint256 value,
    bytes memory data,
    bytes memory signatures
  ) external returns (bytes memory) {
    require(target != address(0), "target zero address");
    require(address(this).balance >= value, "insufficient balance");
    bytes32 dataHash = encodeTransactionData(target, value, data, _nonce, block.chainid);
    _nonce++;
    _checkSignatures(signatures, dataHash);
    (bool success, bytes memory returnData) = target.call{value : value}(data);
    require(success, "call target failed");
    if (success) {
      emit ExecutionSuccess(dataHash);
    } else {
      emit ExecutionFailure(dataHash);
    }
    return returnData;
  }

  function _checkSignatures(bytes memory signatures, bytes32 dataHash) private {
    require(signatures.length >= _threshold * 65, "signatures length");
    address lastOwner = address(0);
    address currentOwner;
    for (uint8 i = 0; i < _threshold; ++i) {
      (bytes32 r, bytes32 s, uint8 v) = _splitSignature(signatures, i);
      currentOwner = ECDSA.recover(ECDSA.toEthSignedMessageHash(dataHash), v, r, s);
      //      currentOwner = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v, r, s);
      require(currentOwner > lastOwner && _isOwner[currentOwner], "current owner should be greater than last owner");
      lastOwner = currentOwner;
    }
  }

  function _splitSignature(bytes memory signatures, uint256 index) private pure returns (bytes32 r, bytes32 s, uint8 v) {
    assembly {
    // 签名的格式: {bytes32 r}{bytes32 s}{uint8 v}
    //      let signaturePos := mul(0x41, index)
    //      r := mload(add(signatures, add(signaturePos, 0x20)))
    //      s := mload(add(signatures, add(signaturePos, 0x40)))
    //      v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
      let signaturePos := mul(65, index)
      r := mload(add(add(signatures, 32), signaturePos))
      s := mload(add(add(signatures, 32), add(signaturePos, 32)))
      v := byte(0, mload(add(add(signatures, 32), add(signaturePos, 64))))

    }
  }

  function encodeTransactionData(
    address target,
    uint256 value,
    bytes memory data,
    uint256 nonce,
    uint256 chainId
  ) public pure returns (bytes32) {
    return keccak256(abi.encode(target, value, keccak256(data), nonce, chainId));
  }
}

contract MultiSigWallet_Test is Test {
  function testMultiSigWallet() public {
    string memory sepoliaRpcUrl = vm.envString("sepolia");
    vm.createSelectFork(sepoliaRpcUrl);

    address alice = 0x65047fbb4be8fC1DE7dB83A7EfA3865d10952411;
    address bob = 0xcC9cF9F400Ef2efB554813184e2F18aD98C637cE;
    address[] memory owners = new address[](2);
    owners[0] = alice;
    owners[1] = bob;
    MultiSigWallet wallet = new MultiSigWallet(owners, 2);
    payable(address(wallet)).transfer(100 ether);

    bytes32 dataHash = wallet.encodeTransactionData(alice, 1 ether, bytes(""), 0, block.chainid);
    console2.logBytes32(dataHash);
    bytes memory signatureOfAlice = hex"1a88ea3d40b5765eda5243f7ac7b9d51ef03541749d263627a38b7dd3572191d578507467994532e5598168bdd08f678d4a1a1f9c3a38e2c1ff29e0e5d24f30d1b";
    bytes memory signatureOfBob = hex"fb93aa6d611c7bf1218b25e557c11d635268f9366acabec2caa5d4788b024dba069fbe329b6f0dcb81678b36d729b2ac7bbc7cc0b523a395902c28b1270f905d1b";
    bytes memory signatures = bytes.concat(signatureOfAlice, signatureOfBob);
    console2.logBytes(signatures);

    deal(alice, 0);
    wallet.executeTransaction(alice, 1 ether, bytes(""), signatures);
    assertEq(alice.balance, 1 ether);
  }
}