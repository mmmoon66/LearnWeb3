// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

library LibMerkleProof {
  function verify(
    bytes32[] memory proof,
    bytes32 leaf,
    bytes32 root
  ) internal pure returns (bool) {
    return calculateRoot(proof, leaf) == root;
  }

  function calculateRoot(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
    bytes32 calcHash = leaf;
    for (uint256 i = 0; i < proof.length; ++i) {
      calcHash = _hashPairs(calcHash, proof[i]);
    }
    return calcHash;
  }

  function _hashPairs(bytes32 a, bytes32 b) private pure returns (bytes32) {
    (a, b) = a < b ? (a, b) : (b, a);
    return keccak256(abi.encodePacked(a, b));
  }
}

contract MerkleTreeNFT is ERC721 {
  bytes32 public root;
  mapping(address => bool) mintedAccounts;

  constructor(bytes32 root_) ERC721("Merkle Tree NFT", "MKT") {
    root = root_;
  }

  function mint(address account, uint256 tokenId, bytes32[] calldata proof) external {
    require(!mintedAccounts[account], "already minted");
    require(LibMerkleProof.verify(proof, _hash(account), root), "invalid proof");
    mintedAccounts[account] = true;
    _safeMint(account, tokenId);
  }

  function _hash(address account) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(account));
  }
}