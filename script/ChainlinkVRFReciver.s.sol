// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {ChainlinkVRFReciver} from "../src/ChainlinkVRFReciver.sol";

// forge script script/ChainlinkVRFReciver.s.sol:ChainlinkVRFReciverScript --rpc-url https://polygon-amoy.g.alchemy.com/v2/vkZ5WPCV0qB9Gye9sajMsn9YhdSl7Shy --private-key $WEB3GAMING_PRIVATE_KEY --broadcast --verify --etherscan-api-key 3B5VHH6EPJ17CQGFIHDT3BU5V4UNHIEVQB
/**
== Logs ==
 Deploying contracts with the account: 0x355eb1c3D6dF0642b3abe2785e821C574837C79f
  GettingStartedVRFConsumer address: 0xBd32Bec48cE1d57e2980e1c6Cf2FFF085563171c
   */

contract ChainlinkVRFReciverScript is Script {
    function run() external {
        // 获取部署者私钥
        string memory privateKey = vm.envString("WEB3GAMING_PRIVATE_KEY");
        uint256 deployerPrivateKey = vm.parseUint(string.concat("0x", privateKey));
        address deployerAddress = vm.addr(deployerPrivateKey);
        console.log("Deploying contracts with the account: %s", deployerAddress);
        vm.startBroadcast(deployerPrivateKey);
        // 部署合约
        ChainlinkVRFReciver consumer = new ChainlinkVRFReciver();
        console.log("GettingStartedVRFConsumer address: %s", address(consumer));
        vm.stopBroadcast();
    }
}