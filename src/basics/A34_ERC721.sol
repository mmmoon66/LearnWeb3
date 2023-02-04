// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERC165 {
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 {
  event Transfer(address indexed from, address indexed to, uint256 indexed id);
  event Approval(address indexed owner, address indexed spender, uint256 indexed id);
  event ApprovalForAll(address indexed owner, address indexed spender, bool approved);

  function balanceOf(address owner) external view returns (uint256);

  function ownerOf(uint256 id) external view returns (address);

  function transferFrom(address from, address to, uint256 id) external;

  function safeTransferFrom(address from, address to, uint256 id) external;

  function safeTransferFrom(address from, address to, uint256 id, bytes calldata data) external;

  function approve(address spender, uint256 id) external;

  function setApprovalForAll(address operator, bool approved) external;

  function getApproved(uint256 id) external view returns (address);

  function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Metadata {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function fromURI(uint256 id) external view returns (string memory);
}

abstract contract ERC721 is IERC165, IERC721, IERC721Metadata {
//  event Transfer(address indexed from, address indexed to, uint256 indexed id);
//  event Approval(address indexed owner, address indexed spender, uint256 indexed id);
//  event ApprovalForAll(address indexed owner, address indexed spender, bool approved);

  string internal _name;
  string internal _symbol;
  mapping(uint256 => address) internal _ownerOf;
  mapping(address => uint256) internal _balanceOf;
  // tokenId => approved
  mapping(uint256 => address) internal _approved;
  // owner => operator => approved
  mapping(address => mapping(address => bool)) internal _isApprovedForAll;

  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
  }

  function fromURI(uint256 id) public view virtual returns (string memory);

  function name() external view returns (string memory) {
    return _name;
  }

  function symbol() external view returns (string memory) {
    return _symbol;
  }

  function ownerOf(uint256 id) public view virtual returns (address owner) {
    owner = _ownerOf[id];
    require(owner != address(0), "Not minted");
  }

  function balanceOf(address owner) public view virtual returns (uint256) {
    require(owner != address(0), "zero address");
    return _balanceOf[owner];
  }

  function safeTransferFrom(address from, address to, uint256 id, bytes calldata data) public virtual {
    transferFrom(from, to, id);

    require(
      to.code.length == 0 ||
      ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) == ERC721TokenReceiver.onERC721Received.selector,
      "unsafe recipient"
    );
  }

  function safeTransferFrom(address from, address to, uint256 id) public virtual {
    transferFrom(from, to, id);

    require(
      to.code.length == 0 ||
      ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") == ERC721TokenReceiver.onERC721Received.selector,
      "unsafe recipient"
    );
  }

  function transferFrom(address from, address to, uint256 id) public virtual {
    require(from == _ownerOf[id], "from not owner");
    require(to != address(0), "invalid recipient");
    require(msg.sender == from || _isApprovedForAll[from][msg.sender] || msg.sender == _approved[id], "not authorized");

  unchecked {
    _balanceOf[from]--;
    _balanceOf[to]++;
  }

    _ownerOf[id] = to;

    delete _approved[id];

    emit Transfer(from, to, id);
  }

  function approve(address spender, uint256 id) public {
    address owner = _ownerOf[id];
    require(msg.sender == owner || _isApprovedForAll[owner][msg.sender], "not authorized");
    _approved[id] = spender;
    emit Approval(owner, spender, id);
  }

  function setApprovalForAll(address operator, bool approved) public virtual {
    _isApprovedForAll[msg.sender][operator] = approved;
    emit ApprovalForAll(msg.sender, operator, approved);
  }

  function getApproved(uint256 id) public view returns (address) {
    return _approved[id];
  }

  function isApprovedForAll(address owner, address operator) public view returns (bool) {
    return _isApprovedForAll[owner][operator];
  }

  function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
    return interfaceId == type(IERC165).interfaceId
    || interfaceId == type(IERC721).interfaceId
    || interfaceId == type(IERC721Metadata).interfaceId;
  }

  function _mint(address to, uint256 id) internal virtual {
    require(to != address(0), "invalid recipient");
    require(_ownerOf[id] == address(0), "already minted");
  unchecked {
    _balanceOf[to]++;
  }
    _ownerOf[id] = to;
    emit Transfer(address(0), to, id);
  }

  function _burn(uint256 id) internal virtual {
    address owner = _ownerOf[id];
    require(owner != address(0), "not minted");
  unchecked {
    _balanceOf[owner]--;
  }
    delete _ownerOf[id];
    delete _approved[id];
    emit Transfer(owner, address(0), id);
  }

  function _safeMint(address to, uint256 id) internal virtual {
    _mint(to, id);
    require(
      to.code.length == 0 ||
      ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") == ERC721TokenReceiver.onERC721Received.selector,
      "unsafe recipient"
    );
  }

  function _safeMint(address to, uint256 id, bytes calldata data) internal virtual {
    _mint(to, id);
    require(
      to.code.length == 0 ||
      ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) == ERC721TokenReceiver.onERC721Received.selector,
      "unsafe recipient"
    );
  }
}

abstract contract ERC721TokenReceiver {
  function onERC721Received(address, address, uint256, bytes calldata) external virtual returns (bytes4) {
    return ERC721TokenReceiver.onERC721Received.selector;
  }
}