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
    event RequestSent(uint256 indexed requestId, uint32 numWords);
    event RequestFulfilled(uint256 indexed requestId, uint256[] randomWords);
    event CallerAdded(address indexed caller);
    event CallerRemoved(address indexed caller);
    event ResponseStatusRemoved(uint256 indexed requestId);
    event ReciverRandomWordsErrorCall(address indexed callee, uint256 indexed requestId, string err);

    error ZeroAddress();
    error ReciverRandomWordsError(string err);
    error CallerNotAllowed(address caller);
    error ResponseNotFound(uint256 requestId);

    mapping(uint256 => uint256[]) public s_requests; /* requestId --> requestStatus */
    mapping(address => bool) public allowedCallers;

    uint256 public s_subscriptionId;
    bytes32 public s_keyHash;
    IVRFCoordinatorV2Plus public s_vrfCoordinator;

    modifier onlyOwnerOrAllowedCaller(address caller) {
        if (!allowedCallers[caller]) {
            revert CallerNotAllowed(caller);
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _owner, address _vrfCoordinator, uint256 _subscriptionId, bytes32 _keyHash) public initializer {
        __Ownable_init(_owner);
        __UUPSUpgradeable_init();
        _initializeVRF(_vrfCoordinator);
        s_subscriptionId = _subscriptionId;
        s_keyHash = _keyHash;
        allowedCallers[_owner] = true;
        emit CallerAdded(_owner);
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
        uint32 callbackGasLimit
        ) onlyOwnerOrAllowedCaller(msg.sender) external returns (uint256 requestId) {
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s_keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: enableNativePayment}))
            })
        );
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] calldata _randomWords) internal override {
        s_requests[_requestId] = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function getResponse(uint256 _requestId)
        external
        view
        returns (uint256[] memory randomWords)
    {
        uint256[] memory response = s_requests[_requestId];
        if (response.length == 0) {
            revert ResponseNotFound(_requestId);
        }
        return response;
    }

    /**
     * @notice Allows the owner to remove the status of a specific VRF request.
     * @param _requestId The ID of the request status to remove.
     * @dev This only removes the entry from the s_requests mapping.
     */
    function removeResponse(uint256 _requestId) external onlyOwner {
        uint256[] memory response = s_requests[_requestId];
        if (response.length != 0) {
            delete s_requests[_requestId];
            emit ResponseStatusRemoved(_requestId);
        } else {
            revert ResponseNotFound(_requestId);
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

    function setSubscriptionId(uint256 _subscriptionId) external onlyOwner {
        s_subscriptionId = _subscriptionId;
    }

    function setKeyHash(bytes32 _keyHash) external onlyOwner {
        s_keyHash = _keyHash;
    }

     function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

}
