// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";

import {CrossChainPriceNFT} from "../src/ccip_minter/CrossChainPriceNFT.sol";

// forge script script/CrossChainPriceNFT.s.sol:CrossChainPriceNFTScript --rpc-url $WEB3GAMING_ALCHEMY_RPC_URL --private-key $WEB3GAMING_PRIVATE_KEY --broadcast --verify --etherscan-api-key $WEB3GAMING_ETHERSCAN_API_KEY
/**
 * == Logs ==
  Deploying contracts with the account: 0x355eb1c3D6dF0642b3abe2785e821C574837C79f
  GettingStartedVRFConsumer address: 0xad476162b0577aA7AD4FaF729731380BC8aC4cEa
  Contract owner: 0x355eb1c3D6dF0642b3abe2785e821C574837C79f
 */
contract CrossChainPriceNFTScript is Script {
    function run() external {
        // 获取部署者私钥
        string memory privateKey = vm.envString("WEB3GAMING_PRIVATE_KEY");
        uint256 deployerPrivateKey = vm.parseUint(string.concat("0x", privateKey));
        address deployerAddress = vm.addr(deployerPrivateKey);
        console.log("Deploying contracts with the account: %s", deployerAddress);
        vm.startBroadcast(deployerPrivateKey);
        // 部署合约
        CrossChainPriceNFT consumer = new CrossChainPriceNFT();
        console.log("GettingStartedVRFConsumer address: %s", address(consumer));
        console.log("Contract owner: %s", deployerAddress);
        vm.stopBroadcast();
    }
}
