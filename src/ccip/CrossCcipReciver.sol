// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {CCIPReceiver} from "@chainlink/contracts/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts/src/v0.8/ccip/libraries/Client.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import "../interfaces/ICrossChainReceiverHandler.sol"; // Import the handler interface

/**
 * @title CrossCcipReceiver
 * @notice Receives and validates CCIP messages, then delegates processing to a handler contract.
 * @dev Inherits from CCIPReceiver and ConfirmedOwner. Configuration is set during deployment and managed by the owner.
 */
contract CrossCcipReceiver is CCIPReceiver, ConfirmedOwner {

    // Custom Errors
    error SenderNotAllowed(uint64 sourceChainSelector, address sender); // If the sender is not whitelisted for the source chain
    error InvalidHandlerAddress(address handler); // If the handler address is invalid
    error HandlerCallFailed(); // If the call to the handler contract fails

    error TargetCallFailed(address target, bytes data, bytes reason);
    error InvalidPackedDataLength(uint256 length);


    // Events
    event MessageReceived(
        bytes32 indexed messageId,
        uint64 indexed sourceChainSelector,
        address sender,
        bytes data,
        address handler
    );
    event SenderAllowed(uint64 indexed sourceChainSelector, address indexed sender);
    event SenderDisallowed(uint64 indexed sourceChainSelector, address indexed sender);
    event HandlerUpdated(address indexed oldHandler, address indexed newHandler);

    constructor(address _router, address _initialOwner)
        CCIPReceiver(_router)
        ConfirmedOwner(_initialOwner)
    {
    }

    function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
        address sender = abi.decode(message.sender, (address));
        uint64 sourceChainSelector = message.sourceChainSelector;
        bytes memory packedData = message.data;
        
       (address targetContract, bytes memory targetCallDataForHandler) = _loadPackedData(packedData);

        // Emit event before calling handler
        emit MessageReceived(message.messageId, sourceChainSelector, sender, targetCallDataForHandler, targetContract);

        // Call the handler contract to process the message
        try ICrossChainReceiverHandler(targetContract).handleMessage(sourceChainSelector, sender, targetCallDataForHandler) returns (bool success) {
            if (!success) {
                revert HandlerCallFailed();
            }
        } catch (bytes memory reason) {
             revert(string(abi.encodePacked("HandlerCallFailed: ", string(reason))));
        }
    }

    function _loadPackedData(bytes memory packedData) internal pure returns (address, bytes memory) {
        uint256 dataLength = packedData.length;
        if (dataLength < 20) {
            revert InvalidPackedDataLength(dataLength); // Must be at least 20 bytes for the address
        }

        address targetContract;
        bytes memory targetCallData;
        assembly {
            // Load the first 32 bytes from packedData (address is right-aligned)
            let word0 := mload(add(packedData, 0x20))
            // Extract address (last 20 bytes of the first word)
            targetContract := and(word0, 0xffffffffffffffffffffffffffffffffffffffff)

            // Calculate the length of the targetCallData
            let callDataLength := sub(dataLength, 20)
            // Allocate memory for targetCallData (+32 bytes for length prefix)
            targetCallData := mload(0x40)
            // Store the length prefix
            mstore(targetCallData, callDataLength)
            // Copy the call data itself (starts after the 20-byte address)
            // Source offset: packedData.offset + 20
            // Destination offset: targetCallData + 32 (after length prefix)
            let srcOffset := add(packedData, 52)
            let destOffset := add(targetCallData, 32)
            // for { let i := 0 } lt(i, callDataLength) { i := add(i, 32) } {
            //     mstore(add(destOffset, i), mload(add(srcOffset, i)))
            // }
            for { let i := 0 } lt(i, callDataLength) { i := add(i, 32) } {
                let chunkSize := sub(callDataLength, i)
                if gt(chunkSize, 32) { chunkSize := 32 }
                let temp := mload(add(srcOffset, i))
                if lt(chunkSize, 32) {
                    let mask := sub(shl(mul(8, sub(32, chunkSize)), 1), 1)
                    temp := and(temp, not(mask))
                }
                mstore(add(destOffset, i), temp)
            }
            // Update free memory pointer
            mstore(0x40, add(targetCallData, add(callDataLength, 32)))
        }
        return (
            targetContract,
            targetCallData
        );
    }

}