// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IBridge {
  struct Message {
    // Message ID.
    uint256 id;
    // Message sender address (auto filled).
    address sender;
    // Source chain ID (auto filled).
    uint256 srcChainId;
    // Destination chain ID where the `to` address lives (auto filled).
    uint256 destChainId;
    // Owner address of the bridged asset.
    address owner;
    // Destination owner address.
    address to;
    // Alternate address to send any refund. If blank, defaults to owner.
    address refundAddress;
    // Deposited Ether minus the processingFee.
    uint256 depositValue;
    // callValue to invoke on the destination chain, for ERC20 transfers.
    uint256 callValue;
    // Processing fee for the relayer. Zero if owner will process themself.
    uint256 processingFee;
    // gasLimit to invoke on the destination chain, for ERC20 transfers.
    uint256 gasLimit;
    // callData to invoke on the destination chain, for ERC20 transfers.
    bytes data;
    // Optional memo.
    string memo;
  }

  function sendMessage(
    Message calldata message
  ) external payable returns (bytes32 msgHash);
}

/*
forge create src/taiko/L1Bank.sol:L1Bank --private-key=$guoliang_private_key
Deployer: 0x65047fbb4be8fC1DE7dB83A7EfA3865d10952411
Deployed to: 0xe53d6c07D7f081B1831CD273d2d883E212A66115
Transaction hash: 0xa683f81f60911f28c0f65a609b85ecb0b1b260498e9e941c6494ef7f3995c448
*/
contract L1Bank {
  event CrossChainDeposit(
    address indexed sender,
    address indexed recipient,
    bytes32 indexed messageHash,
    uint256 processingFee,
    uint256 depositAmount
  );

  address private immutable BRIDGE_ADDRESS = 0x2aB7C0ab9AB47fcF370d13058BfEE28f2Ec0940c;
  address private immutable L2_BANK_ADDRESS = 0x3E6c9887385Ec79B413b809feA72F7C8117D7C02;
  uint256 private immutable L2_CHAIN_ID = 167004;
  uint256 private immutable L2_BANK_DEPOSIT_ESTIMATED_GAS = 45883;

  function crossChainDeposit(
    address recipient,
    uint256 processingFee
  ) external payable {
    require(recipient != address(0), "recipient zero address");
    require(msg.value > processingFee, "insufficient value");
    uint256 depositAmount = msg.value - processingFee;
    IBridge.Message memory message;
    message.destChainId = L2_CHAIN_ID;
    message.owner = msg.sender;
    message.to = L2_BANK_ADDRESS;
    message.refundAddress = msg.sender;
    message.depositValue = 0;
    message.callValue = depositAmount;
    message.processingFee = processingFee;
    message.gasLimit = L2_BANK_DEPOSIT_ESTIMATED_GAS * 2;
    message.data = abi.encodeWithSignature("deposit(address)", recipient);
    message.memo = "deposit from l1 bank";
    bytes32 messageHash = IBridge(BRIDGE_ADDRESS).sendMessage{value: msg.value}(message);
    emit CrossChainDeposit(msg.sender, recipient, messageHash, processingFee, depositAmount);
  }
}