// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
 
// Deploy this contract on Sepolia
// Use the address of the NFT contract when deploy the minter
// Call function testMint() to check if the mint function can be called successfully from CrossDestinationMinter.sol
// Call function testMessage() to mock cross-chain message
 
import {Client} from "@chainlink/contracts/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts/src/v0.8/ccip/applications/CCIPReceiver.sol";
 
interface InftMinter {
    function mintFrom(address account, uint256 sourceId) external;
}
 
/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */
contract CrossDestinationMinter is CCIPReceiver {
    InftMinter public nft;
 
    event MintCallSuccessfull();
    // https://docs.chain.link/ccip/supported-networks/testnet
    address routerSepolia = 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59;
 
    constructor(address nftAddress) CCIPReceiver(routerSepolia) {
        nft = InftMinter(nftAddress);
    }
 
    function _ccipReceive(
        Client.Any2EVMMessage memory message
    ) internal override {
        (bool success, ) = address(nft).call(message.data);
        require(success, "Call failed");
        //latestSourceChainSelector = message.sourceChainSelector
        emit MintCallSuccessfull();
    }
 
    function testMint() external {
        // Mint from Sepolia
        nft.mintFrom(msg.sender, 0);
    }
 
    function testMessage() external {
        // Mint from Sepolia
        bytes memory message;
        message = abi.encodeWithSignature("mintFrom(address,uint256)", msg.sender, 0);
 
        (bool success, ) = address(nft).call(message);
        require(success, "Call failed");
        emit MintCallSuccessfull();
    }
 
    function updateNFT(address nftAddress) external {
        nft = InftMinter(nftAddress);
    }
}