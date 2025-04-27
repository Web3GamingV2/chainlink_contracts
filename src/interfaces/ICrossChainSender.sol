// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Client} from "@chainlink/contracts/src/v0.8/ccip/libraries/Client.sol";

interface ICrossChainSender {

    event MessageSent(
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address indexed receiver,
        bytes data,
        address feeToken,
        uint256 fees
    );

    function sendMessage(
        uint64 _destinationChainSelector,
        address _receiver,
        address _targetContract, // Address of the contract to call on destination
        bytes calldata _targetCallData, // Encoded call data for the target contract
        uint256 _gasLimit // Use 0 for default gas limit estimation by CCIP Router
    ) external returns (bytes32 messageId);
}