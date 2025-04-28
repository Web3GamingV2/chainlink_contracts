// SPDX-License-Identifier: MIT
// An example of a consumer contract that directly pays for each request.
pragma solidity ^0.8.19;

import {IVRFCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

import "./interfaces/IChainlinkVRFCellee.sol";
import "./interfaces/IChainlinkVRF.sol";

contract ChainlinkVRF is VRFConsumerBaseV2Plus, IChainlinkVRF {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords, bytes data, bool success);
    event CallerAdded(address indexed caller);
    event CallerRemoved(address indexed caller);
    event RandomWordsFulfilledCallee(address indexed callee, uint256 indexed requestId, uint256[] randomWords);
    event RequestStatusRemoved(uint256 indexed requestId);
    event ReciverRandomWordsErrorCall(address indexed callee, uint256 indexed requestId, string err);

    // error ZeroAddress();
    error ReciverRandomWordsError(string err);
    error CallerNotAllowed(address caller);
    error RequestNotFound(uint256 requestId);

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
        address callee;
    }

    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */
    mapping(address => bool) public allowedCallers;

    uint256 public s_subscriptionId;

    uint256[] public requestIds;
    uint256 public lastRequestId;
    bytes32 public keyHash;

    modifier onlyOwnerOrAllowedCaller(address caller) {
        if (!allowedCallers[caller]) {
            revert CallerNotAllowed(caller);
        }
        _;
    }
    constructor(address _owner, address _vrfCoordinator, uint256 _subscriptionId, bytes32 _keyHash) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        s_subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        allowedCallers[_owner] = true;
        emit CallerAdded(_owner);
    }

    function requestRandomWords(
        bool enableNativePayment, 
        uint32 numWords,
        uint16 requestConfirmations,
        uint32 callbackGasLimit,
        address callee
        ) external returns (uint256 requestId) {
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: enableNativePayment}))
            })
        );
        s_requests[requestId] = RequestStatus({randomWords: new uint256[](0), exists: true, fulfilled: false, callee: callee});
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] calldata _randomWords) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        address callee = s_requests[_requestId].callee;
        emit RandomWordsFulfilledCallee(callee, _requestId, _randomWords);
        if (callee == address(0)) {
            revert ZeroAddress();
        }
        // string memory err = "RevicerRandom failed: ";
        bytes memory data = abi.encodeWithSignature(
            "revicerRandomWords(uint256[])",
            _randomWords
        );
        (bool success,) = address(callee).call(data);
        // if (!success) {
        //     if (result.length > 0) {
        //         err = string(abi.encodePacked(err, string(result)));
        //     } else {
        //         err = string(abi.encodePacked(err, "No data returned"));
        //     }
        //     emit ReciverRandomWordsErrorCall(callee, _requestId, err);
        //     revert ReciverRandomWordsError(err);
        // }
        emit RequestFulfilled(_requestId, _randomWords, data, success);
    }

    function getRequestStatus(uint256 _requestId)
        external
        view
        returns (bool fulfilled, uint256[] memory randomWords, address callee)
    {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords, request.callee);
    }

    /**
     * @notice Allows the owner to remove the status of a specific VRF request.
     * @param _requestId The ID of the request status to remove.
     * @dev This only removes the entry from the s_requests mapping.
     */
    function removeRequestStatus(uint256 _requestId) external onlyOwner {
        if (!s_requests[_requestId].exists) {
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
