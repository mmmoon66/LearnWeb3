// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Timelock {

  event AdminChanged(address indexed newAdmin);
  event QueueTransaction(bytes32 indexed txHash, address indexed target, uint256 value, string signature, bytes data, uint256 executeTime);
  event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint256 value, string signature, bytes data, uint256 executeTime);
  event CancelTransaction(bytes32 indexed txHash, address indexed target, uint256 value, string signature, bytes data, uint256 executeTime);

  uint256 public immutable GRACE_PERIOD = 7 days;

  address private _admin;
  uint256 private _delay;
  mapping(bytes32 => bool) private _queuedTransactions;

  constructor(uint256 delaySeconds) {
    _admin = msg.sender;
    _delay = delaySeconds;
  }

  modifier onlyAdmin() {
    require(msg.sender == _admin, "Timelock: sender not admin");
    _;
  }

  modifier onlyTimelock() {
    require(msg.sender == address(this), "Timelock: sender not time lock");
    _;
  }

  function admin() public view returns (address) {
    return _admin;
  }

  function changeAdmin(address newAdmin) public onlyTimelock {
    require(newAdmin != address(0), "Timelock: new admin is zero address");
    emit AdminChanged(newAdmin);
    _admin = newAdmin;
  }


  function queueTransaction(
    address target,
    uint256 value,
    string calldata signature,
    bytes calldata data,
    uint256 executeTime
  ) public onlyAdmin {
    require(executeTime >= block.timestamp + _delay, "Timelock: invalid executeTime");
    bytes32 txHash = _getTransactionHash(target, value, signature, data, executeTime);
    require(!_queuedTransactions[txHash], "Timelock: tx already in queue");
    _queuedTransactions[txHash] = true;
    emit QueueTransaction(txHash, target, value, signature, data, executeTime);
  }

  function executeTransaction(
    address target,
    uint256 value,
    string calldata signature,
    bytes calldata data,
    uint256 executeTime
  ) public onlyAdmin payable returns (bytes memory) {
    require(block.timestamp >= executeTime, "Timelock: current time is before executeTime");
    require(block.timestamp <= executeTime + GRACE_PERIOD, "Timelock: tx is expired");
    bytes32 txHash = _getTransactionHash(target, value, signature, data, executeTime);
    require(_queuedTransactions[txHash], "Timelock: tx is not in the queue");
    _queuedTransactions[txHash] = false;
    emit ExecuteTransaction(txHash, target, value, signature, data, executeTime);
    bytes memory calldata_;
    if (bytes(signature).length == 0) {
      calldata_ = data;
    } else {
      calldata_ = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
    }
    (bool success, bytes memory returnData) = target.call{value : value}(calldata_);
    require(success, "call target failed");
    return returnData;
  }

  function cancelTransaction(
    address target,
    uint256 value,
    string calldata signature,
    bytes calldata data,
    uint256 executeTime
  ) public onlyAdmin {
    bytes32 txHash = _getTransactionHash(target, value, signature, data, executeTime);
    require(_queuedTransactions[txHash], "Timelock: tx is not in the queue");
    _queuedTransactions[txHash] = false;
    emit CancelTransaction(txHash, target, value, signature, data, executeTime);
  }

  function _getTransactionHash(
    address target,
    uint256 value,
    string calldata signature,
    bytes calldata data,
    uint256 executeTime
  ) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(target, value, signature, data, executeTime));
  }
}