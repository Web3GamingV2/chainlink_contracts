// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {IRouterClient} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts/src/v0.8/ccip/libraries/Client.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol"; // Import ConfirmedOwner
import {CCIPReceiver} from "@chainlink/contracts/src/v0.8/ccip/applications/CCIPReceiver.sol";

import "../interfaces/ICrossChainReceiverHandler.sol"; // Import the handler interface
import "../interfaces/ICrossChainClient.sol"; // Import the new interface

contract CrossCcip is ICrossChainClient, CCIPReceiver, ConfirmedOwner {

     // Custom Errors
    error SenderNotAllowed(uint64 sourceChainSelector, address sender); // If the sender is not whitelisted for the source chain
    error InvalidHandlerAddress(address handler); // If the handler address is invalid
    error HandlerCallFailed(); // If the call to the handler contract fails

    error TargetCallFailed(address target, bytes data, bytes reason);
    error InvalidPackedDataLength(uint256 length);

    // Custom errors
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees);
    error NothingToWithdraw();
    error InvalidFeeToken(address feeToken); // If fee token is address(0) or not LINK

      // Events
    event MessageReceived(
        bytes32 indexed messageId,
        uint64 indexed sourceChainSelector,
        address sender,
        bytes data,
        address handler
    );
    event SenderAllowed(uint64 indexed destinationChainSelector, address indexed sender);
    event SenderDisallowed(uint64 indexed sourceChainSelector, address indexed sender);
    event HandlerUpdated(address indexed oldHandler, address indexed newHandler);

    address public  routerCCIPClientAddress;
    IRouterClient public  routerCCIPClient;
    LinkTokenInterface public linkTokenClient;

    bool public approved;
    mapping(address => bool) public allowedSenders;

    modifier onlyAllowedSender(uint64 _sourceChainSelector, address _sender) {
        if (!allowedSenders[_sender]) {
            revert SenderNotAllowed(_sourceChainSelector, _sender);
        }
        _;
    }

    constructor(
        address _owner,
        address _routerCCIPClient,
        address _routerCCIPReceiver,
        address _linkTokenClient
    ) ConfirmedOwner(_owner) CCIPReceiver(_routerCCIPReceiver) {
        _initializeCCIPClient(_routerCCIPClient, _linkTokenClient);
        // _initializeCCIPReceiver(_routerCCIPReceiver);
        allowedSenders[_owner] = true;
        approveRouter();
    }

    // function _initializeCCIPReceiver(
    //     address _router
    // ) internal {
    //     require(_router!= address(0), "Router address cannot be zero");
    //     CCIPReceiver(_router);
    // }

    function _initializeCCIPClient(
        address _router,
        address _linkToken
    ) internal {
        require(_router != address(0) && _linkToken != address(0), "Router address cannot be zero");
        routerCCIPClient = IRouterClient(_router);
        linkTokenClient = LinkTokenInterface(_linkToken);
        routerCCIPClientAddress = _router;
    }

    function approveRouter() internal {
        require(routerCCIPClientAddress != address(0), "Router address cannot be zero");
        linkTokenClient.approve(routerCCIPClientAddress, type(uint256).max);
        approved = true;
    }

    // 消息发送方指定目标地址
    // Amoy 调用
    function sendCcip(
        uint64 _destinationChainSelector, // 目标链的 selector
        address _receiver, // 目标链 receiver 的合约地址就是 执行 _ccipReceive 的合约地址
        address _targetContract, // 目标链被调用的合约地址
        bytes calldata _targetCallData, // 目标链被调用的合约的函数 一般是 _ccipReceive 的 message.data
        uint256 _callbackGasLimit // 980_000
    ) external override onlyAllowedSender(_destinationChainSelector, msg.sender) returns (bytes32 messageId) {
        require(_targetContract != address(0) && _receiver != address(0) && approved, "Invalid targetContract address");
        address linkToken = address(linkTokenClient);
        bytes memory combinedData = abi.encodePacked(_targetContract, _targetCallData);
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver),
            data: combinedData,
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: _callbackGasLimit})
            ),
            feeToken: linkToken
        });

        uint256 fees = routerCCIPClient.getFee(_destinationChainSelector, message);
        uint256 currentBalance = linkTokenClient.balanceOf(address(this));
        if (fees > currentBalance) {
            revert NotEnoughBalance(currentBalance, fees);
        }
        messageId = routerCCIPClient.ccipSend(_destinationChainSelector, message);
        emit MessageSent(messageId, _destinationChainSelector, _receiver, combinedData, linkToken, fees);

        return messageId;
    }

     // 消息接收方指定目标地址
    function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
        address sender = abi.decode(message.sender, (address));
        uint64 sourceChainSelector = message.sourceChainSelector;
        bytes memory packedData = message.data;
        
       (address targetContract, bytes memory targetCallDataForHandler) = loadPackedData(packedData);

        bytes memory data = abi.encodeWithSignature(
            "handleCCIPMessage(uint64,address,bytes)",
            sourceChainSelector,
            sender,
            targetCallDataForHandler
        );

        (bool success,) = address(targetContract).call(data);

        if (!success) {
            revert TargetCallFailed(targetContract, targetCallDataForHandler, "Call to target contract failed");
        } else {
            emit MessageReceived(message.messageId, sourceChainSelector, sender, targetCallDataForHandler, targetContract);
        }

    }

    function linkBalance(address account) public view returns (uint256) {
        return linkTokenClient.balanceOf(account);
    }

    function withdrawLink(address beneficiary) public onlyOwner {
        uint256 amount = linkTokenClient.balanceOf(address(this));
        if (amount == 0) revert NothingToWithdraw();
        linkTokenClient.transfer(beneficiary, amount);
    }

    function loadPackedData(bytes memory packedData) external pure returns (address target, bytes memory callData) {
            require(packedData.length >= 20, InvalidPackedDataLength("Packed data too short"));
            // 提取前 20 字节为地址
            bytes20 addrBytes;
            assembly {
                addrBytes := mload(add(packedData, 0x20)) // 读取前 32 字节中的前 20 字节
            }

            target = address(addrBytes);

            // 剩下的是 callData
            uint256 dataLength = packedData.length - 20;
            callData = new bytes(dataLength);
            for (uint256 i = 0; i < dataLength; i++) {
                callData[i] = packedData[i + 20];
            }
    }

}