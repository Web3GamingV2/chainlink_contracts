// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {ChainlinkFCReciver} from "../src/ChainlinkFCReciver.sol";

// forge script script/ChainlinkFCReciver.s.sol:ChainlinkFCReciverScript --rpc-url $WEB3GAMING_ALCHEMY_RPC_URL --private-key $WEB3GAMING_PRIVATE_KEY --broadcast --verify --etherscan-api-key $WEB3GAMING_ETHERSCAN_API_KEY

/**
== Logs ==
  Deploying contracts with the account: 0x355eb1c3D6dF0642b3abe2785e821C574837C79f
  GettingStartedVRFConsumer address: 0x95f30aA4BB54cecd348AEb65A7a40da96e759419
  cast send --rpc-url $WEB3GAMING_ALCHEMY_RPC_URL --private-key $WEB3GAMING_PRIVATE_KEY 0x95f30aA4BB54cecd348AEb65A7a40da96e759419 "requestFunction(uint64,string[],uint32)(bytes32)" 4605 "[1]" 300000
*/

contract ChainlinkFCReciverScript is Script {
    function run() external {
        // 获取部署者私钥
        string memory privateKey = vm.envString("WEB3GAMING_PRIVATE_KEY");
        uint256 deployerPrivateKey = vm.parseUint(string.concat("0x", privateKey));
        address deployerAddress = vm.addr(deployerPrivateKey);
        console.log("Deploying contracts with the account: %s", deployerAddress);
        address fcAddress = 0x90f881b6824928B54B318ff28a2FFb4543F7ec16;
        vm.startBroadcast(deployerPrivateKey);
        // 部署合约
        ChainlinkFCReciver consumer = new ChainlinkFCReciver(fcAddress);
        console.log("GettingStartedVRFConsumer address: %s", address(consumer));
        vm.stopBroadcast();
    }
}