// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

import "./interfaces/IChainlinkFC.sol"; // Import the interface
import "./interfaces/IChainlinkFCCallee.sol"; // Import the callee interface

contract ChainlinkFC is FunctionsClient, ConfirmedOwner, IChainlinkFC {
    using FunctionsRequest for FunctionsRequest.Request;

    mapping(bytes32 => bytes) public s_requests;
    address public s_router;
    address public proxyRouter;
    mapping(address => bool) public allowedCallers;

    event CallerAdded(address indexed caller);
    event CallerRemoved(address indexed caller);
    event Response(bytes32 indexed requestId, string character, bytes response, bytes err);
    event ResponseReceived(bytes32 indexed requestId, bytes response, bytes err);
    event ResponseRemoved(bytes32 indexed requestId);
    event RequestSentReceived(bytes32 indexed requestId, address indexed callee);

    error UnexpectedRequestID(bytes32 requestId);
    error RequestNotFound(bytes32 requestId);
    error CallerNotAllowed(address caller);
    error CallbackFailed(address callee, bytes32 requestId);
    error ZeroAddress();

    modifier onlyOwnerOrAllowedCaller(address caller) {
        if (!allowedCallers[caller]) {
            revert CallerNotAllowed(caller);
        }
        _;
    }

    /**
     * @notice Initializes the contract with the Chainlink router address and sets the contract owner
     */
    constructor(
        address _owner,
        address _proxyRouter,
        address _router
    ) FunctionsClient(_router) ConfirmedOwner(_owner) {
        s_router = _router;
        proxyRouter = _proxyRouter;
        allowedCallers[_owner] = true;
        allowedCallers[_proxyRouter] = true;
        emit CallerAdded(_proxyRouter);
    }

    /**
     * @notice Sends an HTTP request for character information
     * @param subscriptionId The ID for the Chainlink subscription
     * @param args The arguments to pass to the HTTP request
     * @return requestId The ID of the request
     */
    function sendRequest(
        uint64 subscriptionId,
        bytes32 s_donId,
        string[] calldata args, 
        string calldata source,
        uint32 callbackGasLimit
    )
        onlyOwnerOrAllowedCaller(msg.sender)
        external
        returns (bytes32 requestId)
    {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source); // Initialize the request with JS code
        if (args.length > 0) req.setArgs(args); // Set the arguments for the request

        bytes32 s_lastRequestId = _sendRequest(req.encodeCBOR(), subscriptionId, callbackGasLimit, s_donId);
        emit RequestSentReceived(s_lastRequestId, msg.sender); // Emit an event for the request ID and callee address

        return s_lastRequestId;
    }


    function sendRequestCBOR(
        bytes memory request,
        uint64 subscriptionId,
        bytes32 s_donId,
        uint32 gasLimit
    ) external onlyOwner returns (bytes32 requestId) {
        bytes32 s_lastRequestId = _sendRequest(
            request,
            subscriptionId,
            gasLimit,
            s_donId
        );
        emit RequestSentReceived(s_lastRequestId, msg.sender); // Emit an event for the request ID and callee address
        return s_lastRequestId;
    }

    /**
     * @notice Callback function for fulfilling a request
     * @param requestId The ID of the request to fulfill
     * @param response The HTTP response data
     * @param err Any errors from the Functions request
     */
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        s_requests[requestId] = response;
        emit ResponseReceived(requestId, response, err);
    }

    function getResponse(bytes32 _requestId)
        external
        view
        override
        returns (
            bytes memory response
        )
    {
        bytes memory _response = s_requests[_requestId];
        if (_response.length == 0) {
            revert RequestNotFound(_requestId);
        }
        return _response;
    }
    
    function removeResponse(bytes32 _requestId) external onlyOwner {
        bytes memory _response = s_requests[_requestId];
        if (_response.length != 0) {
            delete s_requests[_requestId];
            emit ResponseRemoved(_requestId);
        }
    }

    /**
     * @notice Allows the owner to add an address to the list of allowed callers.
     * @param _caller The address to allow.
     */
    function addCaller(address _caller) external onlyOwner {
        require(_caller != address(0), "Caller cannot be zero address");
        if (!allowedCallers[_caller]) {
            allowedCallers[_caller] = true;
            emit CallerAdded(_caller);
        }
    }

    /**
     * @notice Allows the owner to remove an address from the list of allowed callers.
     * @param _caller The address to disallow.
     */
    function removeCaller(address _caller) external onlyOwner {
        require(_caller != address(0), "Caller cannot be zero address");
        if (allowedCallers[_caller]) {
            allowedCallers[_caller] = false;
            emit CallerRemoved(_caller);
        }
    }
}
