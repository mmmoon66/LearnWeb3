// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console, Test} from "forge-std/Test.sol";
import {IERC165, IERC721, IERC721Metadata, ERC721, ERC721TokenReceiver} from "../A34_ERC721.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract ERC721_Test is Test {
  function testInterfaceId() public {
    console.log("IERC165 interfaceId:");
    console.logBytes4(type(IERC165).interfaceId);
    console.logBytes4(IERC165.supportsInterface.selector);

    console.log("IERC721 interfaceId:");
    console.logBytes4(type(IERC721).interfaceId);
    // calculate interfaceId of IERC721
    bytes4 interfaceId =
    IERC721.balanceOf.selector
    ^ IERC721.ownerOf.selector
    ^ IERC721.transferFrom.selector
    ^ _getSelector("safeTransferFrom(address,address,uint256)")
    ^ _getSelector("safeTransferFrom(address,address,uint256,bytes)")
    ^ IERC721.approve.selector
    ^ IERC721.setApprovalForAll.selector
    ^ IERC721.getApproved.selector
    ^ IERC721.isApprovedForAll.selector;
    console.logBytes4(interfaceId);

    console.log("IERC721Metadata interfaceId:");
    console.logBytes4(type(IERC721Metadata).interfaceId);
    console.logBytes4(
      IERC721Metadata.name.selector
      ^ IERC721Metadata.symbol.selector
      ^ IERC721Metadata.fromURI.selector
    );
  }

  function testSafeMint() public {
    BAYC bayc = new BAYC();

    address alice = vm.addr(1);
    deal(alice, 1 ether);
    vm.prank(alice);
    bayc.safeMint{value : 1 ether}(alice, 0);
    assertEq(bayc.totalSupply(), 1);
    assertEq(bayc.ownerOf(0), alice);
    assertEq(address(bayc).balance, 1 ether);

    NFTReceiver receiver = new NFTReceiver();
    bayc.safeMint{value : 1 ether}(address(receiver), 1);
    assertEq(bayc.totalSupply(), 2);
    assertEq(bayc.ownerOf(1), address(receiver));
    assertEq(address(bayc).balance, 2 ether);

    // transfer nft with id = 1 to alice
    receiver.transfer(address(bayc), alice, 1);
    assertEq(bayc.ownerOf(1), alice);
    assertEq(bayc.balanceOf(alice), 2);

    deal(address(this), 0);
    bayc.withdraw();
    assertEq(address(bayc).balance, 0);
    assertEq(address(this).balance, 2 ether);
  }

  function _getSelector(string memory signature) private pure returns (bytes4) {
    return bytes4(keccak256(abi.encodePacked(signature)));
  }

  receive() external payable {}
}

contract NFTReceiver is ERC721TokenReceiver {
  address public owner;
  constructor() {
    owner = msg.sender;
  }
  function transfer(address nft, address to, uint256 id) external {
    require(msg.sender == owner, "not owner");
    IERC721(nft).safeTransferFrom(address(this), to, id);
  }
}

contract BAYC is ERC721 {
  uint256 public constant MAX_SUPPLY = 10000;

  address public owner;
  uint256 public totalSupply;

  constructor() ERC721("Bored Ape Yacht Club", "BAYC") {
    owner = msg.sender;
  }

  function fromURI(uint256 id) public override pure returns (string memory) {
    return string(abi.encodePacked("ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/", Strings.toString(id)));
  }

  function safeMint(address to, uint256 id) external payable {
    require(id < MAX_SUPPLY, "exceed max supply");
    require(msg.value >= 1 ether, "insufficient value");
    _safeMint(to, id);
    totalSupply++;
  }

  function withdraw() external {
    require(msg.sender == owner, "not owner");
    require(address(this).balance > 0, "zero balance");
    (bool success,) = msg.sender.call{value : address(this).balance}("");
    require(success, "withdraw failed");
  }
}