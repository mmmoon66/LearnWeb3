// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

interface IERC165 {
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IERC165).interfaceId;
  }
}

interface IERC1155 is IERC165 {
  event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
  event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
  event ApprovalForAll(address indexed account, address indexed operator, bool approved);
  event URI(string value, uint256 indexed id);

  function balanceOf(address account, uint256 id) external view returns (uint256);

  function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

  function setApprovalForAll(address operator, bool approved) external;

  function isApprovedForAll(address account, address operator) external view returns (bool);

  function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

  function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

interface IERC1155MetadataURI is IERC1155 {
  function uri(uint256 id) external view returns (string memory);
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
}

interface IERC1155Receiver is IERC165 {
  function onERC1155Received(
    address operator,
    address from,
    uint256 id,
    uint256 value,
    bytes calldata data
  ) external returns (bytes4);

  function onERC1155BatchReceived(
    address operator,
    address from,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    bytes calldata data
  ) external returns (bytes4);
}

abstract contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
  using Address for address;

  // id => account => amount
  mapping(uint256 => mapping(address => uint256)) private _balances;
  // account => operator => approved
  mapping(address => mapping(address => bool)) private _operatorApprovals;
  string private _uri;

  constructor(string memory uri_) {
    _setURI(uri_);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    return
    interfaceId == type(IERC1155).interfaceId ||
    interfaceId == type(IERC1155MetadataURI).interfaceId ||
    super.supportsInterface(interfaceId);
  }

  function uri(uint256 id) public view virtual override returns (string memory) {
    return _uri;
  }

  function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
    require(account != address(0), "ERC1155: address zero is not a valid owner");
    return _balances[id][account];
  }

  function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) public view virtual override returns (uint256[] memory) {
    require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");
    uint256[] memory batchBalances = new uint256[](accounts.length);
    for (uint256 i = 0; i < accounts.length; ++i) {
      batchBalances[i] = balanceOf(accounts[i], ids[i]);
    }
    return batchBalances;
  }

  function setApprovalForAll(address operator, bool approved) public virtual override {
    _setApprovalForAll(_msgSender(), operator, approved);
  }

  function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
    return _operatorApprovals[account][operator];
  }

  function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public virtual override {
    require(from == _msgSender() || isApprovedForAll(from, _msgSender()), "ERC1155: caller is not token owner or approved");
    _safeTransferFrom(from, to, id, amount, data);
  }

  function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] memory amounts, bytes memory data) public virtual override {
    require(from == _msgSender() || isApprovedForAll(from, _msgSender()), "ERC1155: caller is not token owner or approved");
    _safeBatchTransferFrom(from, to, ids, amounts, data);
  }

  function _mint(
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) internal virtual {
    require(to != address(0), "ERC1155: mint to the zero address");
    address operator = _msgSender();
    uint256[] memory ids = _asSingletonArray(id);
    uint256[] memory amounts = _asSingletonArray(amount);
    _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);
    _balances[id][to] += amount;
    emit TransferSingle(operator, address(0), to, id, amount);
    _afterTokenTransfer(operator, address(0), to, ids, amounts, data);
    _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
  }

  function _mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {
    require(to != address(0), "ERC1155: mint to the zero address");
    require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
    address operator = _msgSender();
    _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);
    for (uint256 i = 0; i < ids.length; ++i) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];
      _balances[id][to] += amount;
    }
    emit TransferBatch(operator, address(0), to, ids, amounts);
    _afterTokenTransfer(operator, address(0), to, ids, amounts, data);
    _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
  }

  function _burn(
    address from,
    uint256 id,
    uint256 amount
  ) internal virtual {
    require(from != address(0), "ERC1155: burn from the zero address");
    address operator = _msgSender();
    uint256[] memory ids = _asSingletonArray(id);
    uint256[] memory amounts = _asSingletonArray(amount);
    _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");
    uint256 fromBalance = _balances[id][from];
    require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
    unchecked {
      _balances[id][from] = fromBalance - amount;
    }
    emit TransferSingle(operator, from, address(0), id, amount);
    _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
  }

  function _burnBatch(
    address from,
    uint256[] memory ids,
    uint256[] memory amounts
  ) internal virtual {
    require(from != address(0), "ERC1155: burn from the zero address");
    require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
    address operator = _msgSender();
    _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");
    for (uint256 i = 0; i < ids.length; ++i) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];
      uint256 fromBalance = _balances[id][from];
      require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
      unchecked {
        _balances[id][from] = fromBalance - amount;
      }
    }
    emit TransferBatch(operator, from, address(0), ids, amounts);
    _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
  }

  function _setURI(string memory uri_) internal virtual {
    _uri = uri_;
  }

  function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
    require(owner != operator, "ERC1155: setting approval status for self");
    _operatorApprovals[owner][operator] = approved;
    emit ApprovalForAll(owner, operator, approved);
  }

  function _safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
    require(to != address(0), "ERC1155: transfer to the zero address");
    address operator = _msgSender();
    uint256[] memory ids = _asSingletonArray(id);
    uint256[] memory amounts = _asSingletonArray(amount);
    _beforeTokenTransfer(operator, from, to, ids, amounts, data);
    uint256 fromBalance = _balances[id][from];
    require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
    unchecked {
      _balances[id][from] = fromBalance - amount;
    }
    _balances[id][to] += amount;
    emit TransferSingle(operator, from, to, id, amount);
    _afterTokenTransfer(operator, from, to, ids, amounts, data);
    _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
  }

  function _safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
    require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
    require(to != address(0), "ERC1155: transfer to the zero address");
    address operator = _msgSender();
    _beforeTokenTransfer(operator, from, to, ids, amounts, data);
    for (uint256 i = 0; i < ids.length; ++i) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];
      uint256 fromBalance = _balances[id][from];
      require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
      unchecked {
        _balances[id][from] = fromBalance - amount;
      }
      _balances[id][to] += amount;
    }
    emit TransferBatch(operator, from, to, ids, amounts);
    _afterTokenTransfer(operator, from, to, ids, amounts, data);
    _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {}

  function _afterTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {}

  function _doSafeTransferAcceptanceCheck(
    address operator,
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) private {
    if (to.isContract()) {
      try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (
        bytes4 response
      ) {
        if (response != IERC1155Receiver.onERC1155Received.selector) {
          revert("IERC1155: ERC1155Receiver rejected tokens");
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert("IERC1155: transfer to non-ERC1155Receive implementer");
      }
    }
  }

  function _doSafeBatchTransferAcceptanceCheck(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) private {
    if (to.isContract()) {
      try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
        bytes4 response
      ) {
        if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
          revert("ERC1155: ERC1155Receiver rejected tokens");
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert("ERC1155: transfer to non-ERC1155Receiver implementer");
      }
    }
  }

  function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
    uint256[] memory array = new uint256[](1);
    array[0] = element;
    return array;
  }
}

