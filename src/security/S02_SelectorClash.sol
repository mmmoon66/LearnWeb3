// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract SelectorClash {
  bool private _solved;

  function putCurEpochConPubKeyBytes(bytes memory _bytes) public {
    require(msg.sender == address(this), "Not Owner");
    _solved = true;
  }

  function executeCrossChainTx(bytes memory _method, bytes memory _bytes) public {
    bytes memory _calldata = abi.encode(bytes4(keccak256(abi.encodePacked(_method, "(bytes,bytes,uint64)"))), _bytes);
    (bool success,) = address(this).call(_calldata);
    require(success, "execute cross chain tx failed");
  }

  function solved() public view returns (bool) {
    return _solved;
  }
}