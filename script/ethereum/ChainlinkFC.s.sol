// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ChainlinkFC} from "../../src/ChainlinkFC.sol";

// https://docs.chain.link/chainlink-functions/supported-networks

// forge script script/ethereum/ChainlinkFC.s.sol:ChainlinkFCScript --rpc-url $WEB3GAMING_ALCHEMY_RPC_URL --private-key $WEB3GAMING_PRIVATE_KEY --broadcast --verify --etherscan-api-key $WEB3GAMING_ETHERSCAN_API_KEY
/**
 == Logs ==
  Deploying contracts with the account: 0x355eb1c3D6dF0642b3abe2785e821C574837C79f
  GettingStartedFunctionsConsumer address: 0xc33c5f7e1d1Cb2E3D8a3d8d3a105Aee5561AB5D2
  Contract owner: 0x355eb1c3D6dF0642b3abe2785e821C574837C79f
  Is deployer owner? true
 *   cast send --rpc-url $WEB3GAMING_ALCHEMY_RPC_URL --private-key $WEB3GAMING_PRIVATE_KEY 0x2fA187E546862D5d3B614BF9E733f92A1DB91070 "sendRequest(uint64,string[])(bytes32)" 4605 "[1]"
     cast call --rpc-url $WEB3GAMING_ALCHEMY_RPC_URL 0x90f881b6824928B54B318ff28a2FFb4543F7ec16 "allowedCallers(address)(bool)" 0x95f30aA4BB54cecd348AEb65A7a40da96e759419
     cast send --rpc-url $WEB3GAMING_ALCHEMY_RPC_URL --private-key $WEB3GAMING_PRIVATE_KEY 0x90f881b6824928B54B318ff28a2FFb4543F7ec16 "addCaller(address)" 0x95f30aA4BB54cecd348AEb65A7a40da96e759419
 */ 

contract ChainlinkFCScript is Script {
    function run() external {
        // 获取部署者私钥
        string memory privateKey = vm.envString("WEB3GAMING_PRIVATE_KEY");
        uint256 deployerPrivateKey = vm.parseUint(string.concat("0x", privateKey));
        address deployerAddress = vm.addr(deployerPrivateKey);
        console.log("Deploying contracts with the account: %s", deployerAddress);

        address router = 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0;
        // bytes32 donID = 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000;

        vm.startBroadcast(deployerPrivateKey);
        // 部署合约
        ChainlinkFC consumer = new ChainlinkFC(
            deployerAddress,
            deployerAddress,
            router
        );
        console.log("GettingStartedFunctionsConsumer address: %s", address(consumer));
        console.log("Contract owner: %s", consumer.owner());
        console.log("Is deployer owner? %s", consumer.owner() == deployerAddress);
        vm.stopBroadcast();
    }
}
