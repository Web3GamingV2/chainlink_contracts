// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

import "./interfaces/IChainlinkFC.sol"; // Import the interface
import "./interfaces/IChainlinkFCCallee.sol"; // Import the callee interface

contract ChainlinkFC is FunctionsClient, ConfirmedOwner, IChainlinkFC {
    using FunctionsRequest for FunctionsRequest.Request;

    mapping(bytes32 => RequestStatus) public s_requests;
    bytes32 public s_donId;
    address public s_router;

    // Custom error type
    error UnexpectedRequestID(bytes32 requestId);
    // Event to log responses
    event Response(bytes32 indexed requestId, string character, bytes response, bytes err);
    error RequestNotFound(bytes32 requestId);
    error CallbackFailed(address callee, bytes32 requestId);


    /**
     * @notice Initializes the contract with the Chainlink router address and sets the contract owner
     */
    constructor(
        address _router,
        bytes32 _donId,
        address _owner
    ) FunctionsClient(_router) ConfirmedOwner(_owner) {
        s_router = _router;
        s_donId = _donId;
    }

    /**
     * @notice Sends an HTTP request for character information
     * @param subscriptionId The ID for the Chainlink subscription
     * @param args The arguments to pass to the HTTP request
     * @return requestId The ID of the request
     */
    function sendRequest(
        uint64 subscriptionId,
        string[] calldata args, 
        string calldata source, // Pass source code as argument
        uint32 gasLimit,      // Pass gas limit as argument
        address callee
    )
        external
        onlyOwner
        returns (bytes32 requestId)
    {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source); // Initialize the request with JS code
        if (args.length > 0) req.setArgs(args); // Set the arguments for the request

        // Send the request and store the request ID
        bytes32 s_lastRequestId = _sendRequest(req.encodeCBOR(), subscriptionId, gasLimit, s_donId);

        s_requests[requestId] = RequestStatus({
            fulfilled: false,
            exists: true,
            response: "",
            err: "",
            callee: callee
        });

        emit RequestSent(requestId, callee); 

        return s_lastRequestId;
    }

    /**
     * @notice Callback function for fulfilling a request
     * @param requestId The ID of the request to fulfill
     * @param response The HTTP response data
     * @param err Any errors from the Functions request
     */
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
         RequestStatus storage request = s_requests[requestId];
        if (!request.exists) {
            revert UnexpectedRequestID(requestId); // Check if request IDs match
        }
        request.fulfilled = true;
        request.response = response;
        request.err = err;
        emit ResponseReceived(requestId, response, err);

         address callee = request.callee;
        if (callee != address(0)) {
            try IChainlinkFCCallee(callee).receiveFunctionResponse(requestId, response, err) returns (bool success) {
                require(success, CallbackFailed(callee, requestId));
            } catch (bytes memory reason) {
                revert(string(abi.encodePacked("ResponseReceived: ", string(reason))));
            }
        }
    }

    function getRequestStatus(bytes32 _requestId)
        external
        view
        override
        returns (
            bool fulfilled,
            bytes memory response,
            bytes memory err,
            address callee
        )
    {
        RequestStatus storage request = s_requests[_requestId];
        if (!request.exists) {
            revert RequestNotFound(_requestId);
        }
        return (request.fulfilled, request.response, request.err, request.callee);
    }
}
