// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {VerifySignature, SignatureNFT} from "../A37_Signature.sol";

contract Signature_Test is Test {
  /**
  私钥: 0x227dbb8586117d55284e26620bc76534dfbd2394be34cf4a09cb775d593b6f2b
  公钥: 0xe16C1623c1AA7D919cd2241d8b36d9E79C1Be2A2
  消息: 0x1bf2c0ce4546651a1a2feb457b39d891a6b83931cc2454434f39961345ac378c
  以太坊签名消息: 0xb42ca4636f721c7a331923e764587e98ec577cea1a185f60dfcc14dbb9bd900b
  签名: 0x390d704d7ab732ce034203599ee93dd5d3cb0d4d1d7c600ac11726659489773d559b12d220f99f41d17651b0c1c6a669d346a397f8541760d6b32a5725378b241c
  */
  function testVerifySignature() public {
    VerifySignature vs = new VerifySignature();

    // generate messageHash
    address account = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    uint256 tokenId = 0;
    bytes32 messageHash = vs.getMessageHash(account, tokenId);
    assertEq(messageHash, 0x1bf2c0ce4546651a1a2feb457b39d891a6b83931cc2454434f39961345ac378c);

    // sign messageHash
    bytes32 signedMessageHash = vs.getEthSignedMessageHash(messageHash);
    assertEq(signedMessageHash, 0xb42ca4636f721c7a331923e764587e98ec577cea1a185f60dfcc14dbb9bd900b);

    // ethereum.enable();
    // let account = "0xe16C1623c1AA7D919cd2241d8b36d9E79C1Be2A2";
    // let messageHash = "0x1bf2c0ce4546651a1a2feb457b39d891a6b83931cc2454434f39961345ac378c";
    // let signature = await ethereum.request({ method: "personal_sign", params: [account, messageHash]});
    // signature = "0x390d704d7ab732ce034203599ee93dd5d3cb0d4d1d7c600ac11726659489773d559b12d220f99f41d17651b0c1c6a669d346a397f8541760d6b32a5725378b241c";
    address signer = 0xe16C1623c1AA7D919cd2241d8b36d9E79C1Be2A2;
    bytes memory signature = hex"390d704d7ab732ce034203599ee93dd5d3cb0d4d1d7c600ac11726659489773d559b12d220f99f41d17651b0c1c6a669d346a397f8541760d6b32a5725378b241c";
    assert(vs.verifySignature(signedMessageHash, signature, signer));
  }

  function testSignatureNFT() public {
    SignatureNFT nft = new SignatureNFT(0xe16C1623c1AA7D919cd2241d8b36d9E79C1Be2A2);
    address account = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    uint256 tokenId = 0;
    bytes memory signature = hex"390d704d7ab732ce034203599ee93dd5d3cb0d4d1d7c600ac11726659489773d559b12d220f99f41d17651b0c1c6a669d346a397f8541760d6b32a5725378b241c";
    nft.mint(account, tokenId, signature);
    assertEq(nft.ownerOf(tokenId), account);
  }
}