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
    event SenderAllowed(address indexed sender, bool allowed);
    event LoadPackedData(address indexed target, bytes data);
    event CombinePackedData(bytes data);

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

    function approveRouter() external onlyOwner() {
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
        address linkTokenAdress = address(linkTokenClient);
        bytes memory combinedData = _combinePackedData(_targetContract, _targetCallData);
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver),
            data: combinedData,
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: _callbackGasLimit})
            ),
            feeToken: linkTokenAdress
        });
        uint256 fees = routerCCIPClient.getFee(_destinationChainSelector, message);
        uint256 currentBalance = linkTokenClient.balanceOf(address(this));
        if (fees > currentBalance) {
            revert NotEnoughBalance(currentBalance, fees);
        }
        bytes32 _messageId = routerCCIPClient.ccipSend(_destinationChainSelector, message);

        emit MessageSent(_messageId, _destinationChainSelector, _receiver, combinedData, linkTokenAdress, fees);

        return _messageId;
    }

    function sendCcipNative(
        uint64 _destinationChainSelector, // 目标链的 selector
        address _receiver, // 目标链 receiver 的合约地址就是 执行 _ccipReceive 的合约地址
        address _targetContract, // 目标链被调用的合约地址
        bytes calldata _targetCallData, // 目标链被调用的合约的函数 一般是 _ccipReceive 的 message.data
        uint256 _callbackGasLimit // 980_000
    ) external payable onlyAllowedSender(_destinationChainSelector, msg.sender) returns (bytes32 messageId) {
        require(_targetContract!= address(0) && _receiver!= address(0) && approved, "Invalid targetContract address");
        bytes memory combinedData = _combinePackedData(_targetContract, _targetCallData);
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
             receiver: abi.encode(_receiver),
            data: combinedData,
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: _callbackGasLimit})
            ),
            feeToken: address(0)
        });
        uint256 fees = routerCCIPClient.getFee(_destinationChainSelector, message);

        require(msg.value >= fees, "Insufficient native token balance");
        bytes32 _messageId = routerCCIPClient.ccipSend{value: msg.value}(_destinationChainSelector, message);

        emit MessageSent(_messageId, _destinationChainSelector, _receiver, combinedData, address(0), msg.value);

        return _messageId;
    }

     // 消息接收方指定目标地址
    function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
        address sender = abi.decode(message.sender, (address));
        uint64 sourceChainSelector = message.sourceChainSelector;
        bytes memory packedData = message.data;
        
       (address targetContract, bytes memory targetCallDataForHandler) = _loadPackedData(packedData);

       emit LoadPackedData(targetContract, targetCallDataForHandler);

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

    function getLinkBalance() public view returns (uint256) {
        return linkTokenClient.balanceOf(address(this));
    }

    function withdrawLink(address beneficiary) public onlyOwner {
        uint256 amount = linkTokenClient.balanceOf(address(this));
        if (amount == 0) revert NothingToWithdraw();
        linkTokenClient.transfer(beneficiary, amount);
    }

    function _combinePackedData(address target, bytes memory callData) internal pure returns (bytes memory) {
        return abi.encodePacked(target, callData);
    }

    function _loadPackedData(bytes memory packedData) internal pure returns (address target, bytes memory callData) {
            require(packedData.length >= 20, "Packed data too short");
            // 提取前 20 字节为地址
            assembly {
                target := shr(96, mload(add(packedData, 0x20)))
            }
            // 剩下的是 callData
            uint256 dataLength = packedData.length - 20;
            callData = new bytes(dataLength);
            for (uint256 i = 0; i < dataLength; i++) {
                callData[i] = packedData[i + 20];
            }
    }

    function loadPackedData (bytes memory packedData) public returns (address target, bytes memory callData) {
        (address _target, bytes memory _callData) = _loadPackedData(packedData);
        emit LoadPackedData(_target, _callData);
        return (_target, _callData);
    }

    function combinePackedData(address target, bytes memory callData) public returns (bytes memory) {
        bytes memory _returnData = _combinePackedData(target, callData);
        emit CombinePackedData(_returnData);
        return _returnData;
    }

    function addAllowedSender(address _sender) external onlyOwner {
        require(_sender!= address(0), "Sender cannot be zero address");
        allowedSenders[_sender] = true;
        emit SenderAllowed(_sender, true);
    }

    function removeAllowedSender(address _sender) external onlyOwner {
        require(_sender!= address(0), "Sender cannot be zero address");
        allowedSenders[_sender] = false;
        emit SenderAllowed(_sender, false);
    }

    function isAllowedSender(address _sender) external view returns (bool) {
        return allowedSenders[_sender];
    }
    
}