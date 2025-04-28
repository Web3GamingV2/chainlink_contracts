// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {IRouterClient} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts/src/v0.8/ccip/libraries/Client.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol"; // Import ConfirmedOwner
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For generic fee token withdrawal

import "../interfaces/ICrossChainSender.sol"; // Import the new interface

contract CrossCcipSender is ICrossChainSender, ConfirmedOwner { // Implement interface and use ConfirmedOwner

    // Custom errors
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees);
    error NothingToWithdraw();
    error InvalidFeeToken(address feeToken); // If fee token is address(0) or not LINK

    // State variables
    IRouterClient public immutable router; // Make router immutable
    LinkTokenInterface public immutable linkToken; // Make linkToken immutable (assuming LINK is always the fee token)

    constructor(address _routerAddress, address _linkAddress, address _owner) ConfirmedOwner(_owner) {
        // Validate addresses
        require(_routerAddress != address(0), "Invalid router address");
        require(_linkAddress != address(0), "Invalid LINK address");

        router = IRouterClient(_routerAddress);
        linkToken = LinkTokenInterface(_linkAddress);

        // Approve the router to spend LINK tokens on behalf of this contract
        linkToken.approve(_routerAddress, type(uint256).max);
    }

    function sendMessage(
        uint64 _destinationChainSelector,
        address _receiver,
        address _targetContract,
        bytes calldata _targetCallData,
        uint256 _gasLimit
    ) external override onlyOwner returns (bytes32 messageId) {
        require(_targetContract != address(0), "Invalid targetContract address");
        require(_receiver != address(0), "Invalid receiver address");
        bytes memory combinedData = abi.encodePacked(_targetContract, _targetCallData);
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver),
            data: combinedData,
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: _gasLimit})
            ),
            feeToken: address(linkToken)
        });

        // Get the fee required to send the message
        uint256 fees = router.getFee(_destinationChainSelector, message);

        // Check if the contract has enough LINK balance
        uint256 currentBalance = linkToken.balanceOf(address(this));
        if (fees > currentBalance) {
            revert NotEnoughBalance(currentBalance, fees);
        }
        messageId = router.ccipSend(_destinationChainSelector, message);
        emit MessageSent(messageId, _destinationChainSelector, _receiver, combinedData, address(linkToken), fees);

        return messageId;
    }

    function linkBalance(address account) public view returns (uint256) {
        return linkToken.balanceOf(account);
    }

    function withdrawLink(address beneficiary) public onlyOwner {
        uint256 amount = linkToken.balanceOf(address(this));
        if (amount == 0) revert NothingToWithdraw();
        linkToken.transfer(beneficiary, amount);
    }

    function withdrawToken(address tokenAddress, address beneficiary) public onlyOwner {
        require(tokenAddress != address(linkToken), "Use withdrawLink for LINK");
        IERC20 token = IERC20(tokenAddress);
        uint256 amount = token.balanceOf(address(this));
        if (amount == 0) revert NothingToWithdraw();
        token.transfer(beneficiary, amount);
    }

    // Modifier onlyOwner is inherited from ConfirmedOwner
}