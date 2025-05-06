// SPDX-License-Identifier: MIT
// An example of a consumer contract that directly pays for each request.
pragma solidity ^0.8.19;

import "./interfaces/ICrossChainReceiverHandler.sol";

contract ChainlinkCCIPReciver is ICrossChainReceiverHandler {

     event CCIPMessageReceived(
        uint64 indexed sourceChainSelector,
        address sender,
        bytes32 messageId,
        bytes data
    );

    function handleCCIPMessage(
        uint64 sourceChainSelector,
        address sender,
        bytes32 messageId,
        bytes calldata data
    ) external override {
        emit CCIPMessageReceived(sourceChainSelector, sender, messageId, data); // Emit an event to indicate the rando
    }
}
