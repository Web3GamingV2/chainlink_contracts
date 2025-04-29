// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

import "./interfaces/IChainlinkFC.sol"; // Import the interface
import "./interfaces/IChainlinkFCCallee.sol"; // Import the callee interface

contract ChainlinkFC is FunctionsClient, ConfirmedOwner, IChainlinkFC {
    using FunctionsRequest for FunctionsRequest.Request;

    mapping(bytes32 => address) public s_requests;
    bytes32 public s_donId;
    address public s_router;
    address public proxyRouter;
    mapping(address => bool) public allowedCallers;

    event CallerAdded(address indexed caller);
    event CallerRemoved(address indexed caller);
    event Response(bytes32 indexed requestId, string character, bytes response, bytes err);
    event ResponseCallbackFailed(address indexed callee, bytes32 indexed requestId, bytes err);
    event RequestStatusRemoved(bytes32 indexed requestId);
    event RequestSentIndex(bytes32 indexed requestId, address indexed callee);
    event ResponseReceived(bytes32 indexed requestId, address indexed callee, bytes response);

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
        address _router,
        bytes32 _donId
    ) FunctionsClient(_router) ConfirmedOwner(_owner) {
        s_router = _router;
        s_donId = _donId;
        proxyRouter = _proxyRouter;
        allowedCallers[_owner] = true;
        allowedCallers[_proxyRouter] = true;
        emit CallerAdded(_owner);
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
        string calldata source,
        uint32 callbackGasLimit,     
        address callee
    )
        onlyOwnerOrAllowedCaller(callee)
        external
        returns (bytes32 requestId)
    {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source); // Initialize the request with JS code
        if (args.length > 0) req.setArgs(args); // Set the arguments for the request

        bytes32 s_lastRequestId = _sendRequest(req.encodeCBOR(), subscriptionId, callbackGasLimit, s_donId);

        s_requests[requestId] = callee;

        emit RequestSent(requestId); 
        emit RequestSentIndex(requestId, callee); // Emit an event for the request ID and callee address

        return s_lastRequestId;
    }

    /**
     * @notice Callback function for fulfilling a request
     * @param requestId The ID of the request to fulfill
     * @param response The HTTP response data
     * @param err Any errors from the Functions request
     */
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        address callee = s_requests[requestId];
         if (callee == address(0)) {
            revert ZeroAddress();
        }
         bytes memory data = abi.encodeWithSignature(
            "receiveFunctionResponse(bytes32,bytes)",
            requestId,
            response
        );

        (bool success,) = address(callee).call(data);
        if (!success) {
            emit ResponseCallbackFailed(callee, requestId, err);
        } else {
            emit ResponseReceived(requestId, callee, response);
        }
    }

    function getRequestStatus(bytes32 _requestId)
        external
        view
        override
        returns (
            address callee
        )
    {
        address _callee = s_requests[_requestId];
        if (_callee == address(0)) {
            revert RequestNotFound(_requestId);
        }
        return _callee;
    }

    function removeRequestStatus(bytes32 _requestId) external onlyOwner {
         address _callee = s_requests[_requestId];
        if (_callee == address(0)) {
            revert RequestNotFound(_requestId);
        }
        delete s_requests[_requestId];
        emit RequestStatusRemoved(_requestId);
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
