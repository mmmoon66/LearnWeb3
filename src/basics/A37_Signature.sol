// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

library ECDSA {
  error INVALID_SIGNATURE_LENGTH();

  function toEthereumSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
  }

  function recoverSigner(bytes32 signedMessageHash, bytes memory signature) internal pure returns (address) {
    if (signature.length != 65) revert INVALID_SIGNATURE_LENGTH();
    bytes32 r;
    bytes32 s;
    uint8 v;
    assembly {
    // 前32个byte存储signature的长度
    // r的起始位置为 add(signature, 32)
    // s的起始位置为 add(signature, 64)
    // v的起始位置为 add(signature, 96)
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }
    return ecrecover(signedMessageHash, v, r, s);
  }

  function verify(bytes32 signedMessageHash, bytes memory signature, address signer) internal pure returns (bool) {
    return recoverSigner(signedMessageHash, signature) == signer;
  }
}

contract VerifySignature {
  function getMessageHash(address addr, uint256 tokenId) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(addr, tokenId));
  }

  function getEthSignedMessageHash(bytes32 messageHash) public pure returns (bytes32) {
    return ECDSA.toEthereumSignedMessageHash(messageHash);
  }

  function verifySignature(bytes32 signedMessageHash, bytes memory signature, address signer) public pure returns (bool) {
    return ECDSA.verify(signedMessageHash, signature, signer);
  }
}

contract SignatureNFT is ERC721 {
  error INVALID_SIGNER();
  error INVALID_SIGNATURE();
  error ALREADY_MINTED();

  address public signer;
  mapping(address => bool) mintedAddresses;

  constructor(address signer_) ERC721("Signature NFT", "SIG") {
    if (signer_ == address(0)) revert INVALID_SIGNER();
    signer = signer_;
  }

  function mint(address account, uint256 tokenId, bytes memory signature) external {
    bytes32 messageHash = keccak256(abi.encodePacked(account, tokenId));
    bytes32 signedMessageHash = ECDSA.toEthereumSignedMessageHash(messageHash);
    if (!ECDSA.verify(signedMessageHash, signature, signer)) revert INVALID_SIGNATURE();
    if (mintedAddresses[account]) revert ALREADY_MINTED();
    mintedAddresses[account] = true;
    ERC721._safeMint(account, tokenId);
  }
}