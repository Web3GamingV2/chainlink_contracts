// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {ChainlinkCCIPReciver} from "../src/ChainlinkCCIPReciver.sol";

// forge script script/ChainlinkCCIPReciver.s.sol:ChainlinkCCIPReciverScripts --rpc-url $WEB3GAMING_ALCHEMY_RPC_URL --private-key $WEB3GAMING_PRIVATE_KEY --broadcast --verify --etherscan-api-key $WEB3GAMING_ETHERSCAN_API_KEY

/**
== Logs ==
  Deploying contracts with the account: 0x355eb1c3D6dF0642b3abe2785e821C574837C79f
  ChainlinkCCIPReciver address: 0xdE046C3aF9Af4dA935D7DD941b165c966f57eC5D
 *
*/

contract ChainlinkCCIPReciverScripts is Script {
    function run() external {
        // 获取部署者私钥
        string memory privateKey = vm.envString("WEB3GAMING_PRIVATE_KEY");
        uint256 deployerPrivateKey = vm.parseUint(string.concat("0x", privateKey));
        address deployerAddress = vm.addr(deployerPrivateKey);
        console.log("Deploying contracts with the account: %s", deployerAddress);
        vm.startBroadcast(deployerPrivateKey);
        // 部署合约
        ChainlinkCCIPReciver consumer = new ChainlinkCCIPReciver();
        console.log("ChainlinkCCIPReciver address: %s", address(consumer));
        vm.stopBroadcast();
    }
}