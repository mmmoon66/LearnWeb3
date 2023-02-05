// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console, Test} from "forge-std/Test.sol";
import {LibMerkleProof, MerkleTreeNFT} from "../A36_MerkleTree.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract MerkleProof_Test is Test, IERC721Receiver {
  function testVerify() public {
    bytes32[] memory proof = new bytes32[](2);
    proof[0] = 0xdfbe3e504ac4e35541bebad4d0e7574668e16fefa26cd4172f93e18b59ce9486;
    proof[1] = 0x9d997719c0a5b5f6db9b8ac69a988be57cf324cb9fffd51dc2c37544bb520d65;
    bytes32 leaf = 0x04a10bfd00977f54cc3450c9b25c9b3a502a089eba0097ba35fc33c4ea5fcb54;
    bytes32 root = 0xeeefd63003e0e702cb41cd0043015a6e26ddb38073cc6ffeb0ba3e808ba8c097;
    assertEq(LibMerkleProof.verify(proof, leaf, root), true);
  }

  /*
  Tree
  └─ eeefd63003e0e702cb41cd0043015a6e26ddb38073cc6ffeb0ba3e808ba8c097
     ├─ 9d997719c0a5b5f6db9b8ac69a988be57cf324cb9fffd51dc2c37544bb520d65
     │  ├─ 5931b4ed56ace4c46b68524cb5bcbf4195f1bbaacbe5228fbd090546c88dd229
     │  └─ 999bf57501565dbd2fdcea36efa2b9aef8340a8901e3459f4a4c926275d36cdb
     └─ 4726e4102af77216b09ccd94f40daa10531c87c4d60bba7f3b3faf5ff9f19b3c
        ├─ 04a10bfd00977f54cc3450c9b25c9b3a502a089eba0097ba35fc33c4ea5fcb54
        └─ dfbe3e504ac4e35541bebad4d0e7574668e16fefa26cd4172f93e18b59ce9486

  accounts:
  [
    "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4",
    "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2",
    "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db",
    "0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB"
  ]
  */
  function testMint() public {
    bytes32 root = 0xeeefd63003e0e702cb41cd0043015a6e26ddb38073cc6ffeb0ba3e808ba8c097;
    MerkleTreeNFT nft = new MerkleTreeNFT(root);
    address account = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    uint256 tokenId = 666;
    bytes32[] memory proof = new bytes32[](2);
    proof[0] = 0x999bf57501565dbd2fdcea36efa2b9aef8340a8901e3459f4a4c926275d36cdb;
    proof[1] = 0x4726e4102af77216b09ccd94f40daa10531c87c4d60bba7f3b3faf5ff9f19b3c;
    nft.mint(account, tokenId, proof);
    assertEq(nft.ownerOf(tokenId), account);
    assertEq(nft.balanceOf(account), 1);
  }

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4) {
    console.log("operator:", operator);
    console.log("from:", from);
    console.log("tokenId:", tokenId);
//    console.log("data:", data);
    return IERC721Receiver.onERC721Received.selector;
  }

  function transfer(address token, address to, uint256 tokenId) external {
    require(token != address(0), "invalid token address");
    require(to != address(0), "invalid recipient");
    IERC721(token).safeTransferFrom(address(this), to, tokenId);
  }
}