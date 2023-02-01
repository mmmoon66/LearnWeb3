// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// https://github.com/AmazingAng/WTF-Solidity/tree/main/S06_SignatureReplay
contract SignatureReplay is ERC20 {

  address private _signer;

  constructor() ERC20("Signature Replay", "SigReplay") {
    _signer = msg.sender;
  }

  function badMint(address to, uint256 amount, bytes memory signature) public {
    bytes32 hash = ECDSA.toEthSignedMessageHash(getMessageHash(to, amount));
    require(verify(hash, signature), "invalid signature");
    _mint(to, amount);
  }

  function getMessageHash(address to, uint256 amount) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(to, amount));
  }

  function verify(bytes32 hash, bytes memory signature) public view returns (bool) {
    return ECDSA.recover(hash, signature) == _signer;
  }
}