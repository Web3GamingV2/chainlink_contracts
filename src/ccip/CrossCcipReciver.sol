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

    // Address of the handler contract that implements ICrossChainReceiverHandler
    address public messageHandler;

    // Mapping to store allowed senders for specific source chains
    // allowedSenders[sourceChainSelector][senderAddress] => isAllowed
    mapping(uint64 => mapping(address => bool)) public allowedSenders;

    // Custom Errors
    error InvalidRouter(address router); // If the message is not sent by the configured router
    error SenderNotAllowed(uint64 sourceChainSelector, address sender); // If the sender is not whitelisted for the source chain
    error InvalidHandlerAddress(address handler); // If the handler address is invalid
    error HandlerCallFailed(); // If the call to the handler contract fails

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

    /**
     * @notice Constructor initializes the CCIP receiver.
     * @param _router The address of the CCIP Router contract on this chain.
     * @param _initialOwner The initial owner of this contract.
     * @param _handler The address of the contract implementing ICrossChainReceiverHandler to process messages.
     */
    constructor(address _router, address _initialOwner, address _handler)
        CCIPReceiver(_router)
        ConfirmedOwner(_initialOwner)
    {
        if (_handler == address(0)) revert InvalidHandlerAddress(_handler);
        messageHandler = _handler;
        emit HandlerUpdated(address(0), _handler);
    }

    /**
     * @notice Internal function called by the CCIP Router when a message is received.
     * @param message The CCIP message containing source chain, sender, data, etc.
     * @dev Validates the sender and source chain against the allowed list.
     *      If valid, calls the configured message handler contract.
     *      Overrides the function from CCIPReceiver.
     */
    function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
        // Basic validation: Check if the message came from the configured router
        // This check is implicitly done by the CCIPReceiver modifier, but explicit check can be added if needed.
        // if(msg.sender != i_router) revert InvalidRouter(msg.sender);

        // Decode sender address
        // It's important to ensure the sender field is correctly decoded as an address.
        // If the sender format might vary, add more robust decoding/validation.
        address sender = abi.decode(message.sender, (address));
        uint64 sourceChainSelector = message.sourceChainSelector;

        if (!allowedSenders[sourceChainSelector][sender]) {
            revert SenderNotAllowed(sourceChainSelector, sender);
        }

        // Emit event before calling handler
        emit MessageReceived(message.messageId, sourceChainSelector, sender, message.data, messageHandler);

        // Call the handler contract to process the message
        try ICrossChainReceiverHandler(messageHandler).handleMessage(sourceChainSelector, sender, message.data) returns (bool success) {
            if (!success) {
                revert HandlerCallFailed();
            }
        } catch {
            revert HandlerCallFailed();
        }
    }

    // --- Admin Functions ---

    /**
     * @notice Allows the owner to whitelist a sender address for a specific source chain.
     * @param _sourceChainSelector The chain selector of the source chain.
     * @param _sender The address of the sender contract on the source chain.
     */
    function allowSender(uint64 _sourceChainSelector, address _sender) external onlyOwner {
        require(_sender != address(0), "Invalid sender address");
        allowedSenders[_sourceChainSelector][_sender] = true;
        emit SenderAllowed(_sourceChainSelector, _sender);
    }

    /**
     * @notice Allows the owner to remove a sender address from the whitelist for a specific source chain.
     * @param _sourceChainSelector The chain selector of the source chain.
     * @param _sender The address of the sender contract on the source chain.
     */
    function disallowSender(uint64 _sourceChainSelector, address _sender) external onlyOwner {
        require(_sender != address(0), "Invalid sender address");
        allowedSenders[_sourceChainSelector][_sender] = false;
        emit SenderDisallowed(_sourceChainSelector, _sender);
    }

    /**
     * @notice Allows the owner to update the message handler contract address.
     * @param _newHandler The address of the new handler contract.
     */
    function updateHandler(address _newHandler) external onlyOwner {
        if (_newHandler == address(0)) revert InvalidHandlerAddress(_newHandler);
        address oldHandler = messageHandler;
        messageHandler = _newHandler;
        emit HandlerUpdated(oldHandler, _newHandler);
    }

    /**
     * @notice Checks if a specific sender is allowed from a specific source chain.
     * @param _sourceChainSelector The chain selector of the source chain.
     * @param _sender The address of the sender contract on the source chain.
     * @return True if the sender is allowed, false otherwise.
     */
    function isSenderAllowed(uint64 _sourceChainSelector, address _sender) external view returns (bool) {
        return allowedSenders[_sourceChainSelector][_sender];
    }
}