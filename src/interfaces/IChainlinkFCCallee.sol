// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IChainlinkFCCallee {
    /**
     * @notice Callback function to receive the response or error from Chainlink Functions.
     * @param _requestId The ID of the original request.
     * @param _response The response data from the Functions request.
     */
    function receiveFunctionResponse(bytes32 _requestId,bytes memory _response) external;
}