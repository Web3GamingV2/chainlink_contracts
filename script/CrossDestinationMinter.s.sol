// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";

import {CrossDestinationMinter} from "../src/ccip_minter/CrossDestinationMinter.sol";

// forge script script/CrossDestinationMinter.s.sol:CrossDestinationMinterScript --rpc-url $WEB3GAMING_ALCHEMY_RPC_URL --private-key $WEB3GAMING_PRIVATE_KEY --broadcast --verify --etherscan-api-key $WEB3GAMING_ETHERSCAN_API_KEY
/**
 == Logs ==
  Deploying contracts with the account: 0x355eb1c3D6dF0642b3abe2785e821C574837C79f
  CrossDestinationMinter address: 0x6a1D2A1F13cfd9b07CDaE6C703c87A78A19FC809
  Contract owner: 0x355eb1c3D6dF0642b3abe2785e821C574837C79f
  cast send --rpc-url $WEB3GAMING_ALCHEMY_RPC_URL --private-key $WEB3GAMING_PRIVATE_KEY 0x6a1D2A1F13cfd9b07CDaE6C703c87A78A19FC809 "testMint()"
  cast send --rpc-url $WEB3GAMING_ALCHEMY_RPC_URL --private-key $WEB3GAMING_PRIVATE_KEY 0x6a1D2A1F13cfd9b07CDaE6C703c87A78A19FC809 "testMessage()"
 */
contract CrossDestinationMinterScript is Script {
    function run() external {
        // 获取部署者私钥
        string memory privateKey = vm.envString("WEB3GAMING_PRIVATE_KEY");
        uint256 deployerPrivateKey = vm.parseUint(string.concat("0x", privateKey));
        address deployerAddress = vm.addr(deployerPrivateKey);
        console.log("Deploying contracts with the account: %s", deployerAddress);
        address nftAddress = 0xad476162b0577aA7AD4FaF729731380BC8aC4cEa;
        vm.startBroadcast(deployerPrivateKey);
        // 部署合约
        CrossDestinationMinter consumer = new CrossDestinationMinter(nftAddress);
        console.log("CrossDestinationMinter address: %s", address(consumer));
        console.log("Contract owner: %s", deployerAddress);
        vm.stopBroadcast();
    }
}
