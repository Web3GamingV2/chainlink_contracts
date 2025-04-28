// SPDX-License-Identifier: MIT
// An example of a consumer contract that directly pays for each request.
pragma solidity ^0.8.19;

import {IVRFCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
// import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/IChainlinkVRFCellee.sol";
import "./interfaces/IChainlinkVRF.sol";
import "./interfaces/IVRFConsumerBaseV2Plus.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */
contract ChainlinkVRF is IVRFConsumerBaseV2Plus, IChainlinkVRF, Initializable, UUPSUpgradeable, OwnableUpgradeable {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    error ZeroAddress();
    error ReciverRandomWordsError(string err);

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
        address callee;
    }

    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */

    uint256 public s_subscriptionId;
    IVRFCoordinatorV2Plus public s_vrfCoordinator;

    // Past request IDs.
    uint256[] public requestIds;
    uint256 public lastRequestId;
    bytes32 public keyHash;


    /**
     * HARDCODED FOR SEPOLIA
     * COORDINATOR: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B
     * HARDCODED FOR AMOY
     * COORDINATOR: 0x343300b5d84D444B2ADc9116FEF1bED02BE49Cf2
     */
    // constructor(address _vrfCoordinator, uint256 _subscriptionId, bytes32 _keyHash) VRFConsumerBaseV2Plus(_vrfCoordinator) {
    //     s_subscriptionId = _subscriptionId;
    //     keyHash = _keyHash;
    // }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _owner, address _vrfCoordinator, uint256 _subscriptionId, bytes32 _keyHash) public initializer {
        __Ownable_init(_owner);
        __UUPSUpgradeable_init();
        s_subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        _initializeVRF(_vrfCoordinator);
    }

    function _initializeVRF(address _vrfCoordinator) internal {
        if (_vrfCoordinator == address(0)) {
            revert ZeroAddress();
        }
        s_vrfCoordinator = IVRFCoordinatorV2Plus(_vrfCoordinator);
    }

    function requestRandomWords(
        bool enableNativePayment, 
        uint32 numWords,
        uint16 requestConfirmations,
        uint32 callbackGasLimit,
        address callee
        ) external onlyOwner returns (uint256 requestId) {
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
        if (callee != address(0)) {
            try IChainlinkVRFCellee(callee).revicerRandomWords(_randomWords) returns (bool success) {
               if (!success) {
                    revert ReciverRandomWordsError("revicerRandom failed");
                }
            } catch (bytes memory reason) {
                revert(string(abi.encodePacked("RevicerRandom: ", string(reason))));
            }
        }
        emit RequestFulfilled(_requestId, _randomWords);
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

     function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

}
