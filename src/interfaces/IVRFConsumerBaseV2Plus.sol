// SPDX-License-Identifier: MIT
// An example of a consumer contract that directly pays for each request.
pragma solidity ^0.8.19;

abstract contract IVRFConsumerBaseV2Plus {
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal virtual;
}