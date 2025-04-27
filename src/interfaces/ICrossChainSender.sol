// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Client} from "@chainlink/contracts/src/v0.8/ccip/libraries/Client.sol";

interface ICrossChainSender {
    /**
     * @notice Event emitted when a CCIP message is sent.
     * @param messageId The unique identifier of the CCIP message.
     * @param destinationChainSelector The chain selector of the destination chain.
     * @param receiver The address of the receiver contract on the destination chain.
     * @param data The data payload sent in the message.
     * @param feeToken The token used to pay for the CCIP fees.
     * @param fees The amount of fees paid for the message.
     */
    event MessageSent(
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address indexed receiver,
        bytes data,
        address feeToken,
        uint256 fees
    );

    /**
     * @notice Sends a message to another chain via CCIP.
     * @param _destinationChainSelector The chain selector of the destination chain.
     * @param _receiver The address of the receiver contract on the destination chain.
     * @param _data The data payload to send.
     * @param _gasLimit Optional gas limit for the execution on the destination chain.
     * @return messageId The unique identifier of the CCIP message sent.
     * @dev This function should handle fee calculation and payment.
     *      It assumes the contract holds enough fee tokens (LINK by default).
     */
    function sendMessage(
        uint64 _destinationChainSelector,
        address _receiver,
        bytes calldata _data,
        uint256 _gasLimit // Use 0 for default gas limit estimation by CCIP Router
    ) external returns (bytes32 messageId);
}