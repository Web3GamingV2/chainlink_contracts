// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {IRouterClient} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts/src/v0.8/ccip/libraries/Client.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol"; // Import ConfirmedOwner
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For generic fee token withdrawal

import "../interfaces/ICrossChainSender.sol"; // Import the new interface

contract CrossSourceMinter is ICrossChainSender, ConfirmedOwner { // Implement interface and use ConfirmedOwner

    // Custom errors
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees);
    error NothingToWithdraw();
    error InvalidFeeToken(address feeToken); // If fee token is address(0) or not LINK

    // State variables
    IRouterClient public immutable router; // Make router immutable
    LinkTokenInterface public immutable linkToken; // Make linkToken immutable (assuming LINK is always the fee token)

    /**
     * @notice Constructor to initialize the contract.
     * @param _routerAddress The address of the CCIP Router contract on the source chain.
     * @param _linkAddress The address of the LINK token contract on the source chain.
     * @param _owner The initial owner of the contract.
     */
    constructor(address _routerAddress, address _linkAddress, address _owner) ConfirmedOwner(_owner) {
        // Validate addresses
        require(_routerAddress != address(0), "Invalid router address");
        require(_linkAddress != address(0), "Invalid LINK address");

        router = IRouterClient(_routerAddress);
        linkToken = LinkTokenInterface(_linkAddress);

        // Approve the router to spend LINK tokens on behalf of this contract
        linkToken.approve(_routerAddress, type(uint256).max);
    }

    /**
     * @notice Sends a generic message via CCIP using LINK as the fee token.
     * @param _destinationChainSelector The chain selector of the destination chain.
     * @param _receiver The address of the receiver contract on the destination chain.
     * @param _data The data payload to send (e.g., encoded function call).
     * @param _gasLimit Optional gas limit for the execution on the destination chain. Use 0 for default.
     * @return messageId The unique identifier of the CCIP message sent.
     */
    function sendMessage(
        uint64 _destinationChainSelector,
        address _receiver,
        bytes calldata _data,
        uint256 _gasLimit // Use 0 for default gas limit estimation by CCIP Router
    ) external override onlyOwner returns (bytes32 messageId) { // Implement interface method, add onlyOwner
        // Create the CCIP message struct
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver), // abi.encode the receiver address
            data: _data, // Use the provided data payload
            tokenAmounts: new Client.EVMTokenAmount[](0), // No token transfers in this example
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: _gasLimit}) // Use provided gas limit
            ),
            feeToken: address(linkToken) // Pay fees in LINK
        });

        // Get the fee required to send the message
        uint256 fees = router.getFee(_destinationChainSelector, message);

        // Check if the contract has enough LINK balance
        uint256 currentBalance = linkToken.balanceOf(address(this));
        if (fees > currentBalance) {
            revert NotEnoughBalance(currentBalance, fees);
        }

        // Send the message through the router
        messageId = router.ccipSend(_destinationChainSelector, message);

        // Emit the event defined in the interface
        emit MessageSent(messageId, _destinationChainSelector, _receiver, _data, address(linkToken), fees);

        return messageId;
    }

    /**
     * @notice Returns the LINK balance of a given account.
     * @param account The address to check the balance of.
     * @return The LINK token balance.
     */
    function linkBalance(address account) public view returns (uint256) {
        return linkToken.balanceOf(account);
    }

    /**
     * @notice Allows the owner to withdraw LINK tokens from the contract.
     * @param beneficiary The address to receive the withdrawn tokens.
     */
    function withdrawLink(address beneficiary) public onlyOwner {
        uint256 amount = linkToken.balanceOf(address(this));
        if (amount == 0) revert NothingToWithdraw();
        linkToken.transfer(beneficiary, amount);
    }

    /**
     * @notice Allows the owner to withdraw any ERC20 token accidentally sent to this contract.
     * @dev Excludes the LINK token which is handled by withdrawLink.
     * @param tokenAddress The address of the ERC20 token to withdraw.
     * @param beneficiary The address to receive the withdrawn tokens.
     */
    function withdrawToken(address tokenAddress, address beneficiary) public onlyOwner {
        require(tokenAddress != address(linkToken), "Use withdrawLink for LINK");
        IERC20 token = IERC20(tokenAddress);
        uint256 amount = token.balanceOf(address(this));
        if (amount == 0) revert NothingToWithdraw();
        token.transfer(beneficiary, amount);
    }

    // Modifier onlyOwner is inherited from ConfirmedOwner
}