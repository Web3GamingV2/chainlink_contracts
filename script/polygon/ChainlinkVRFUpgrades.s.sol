// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {ChainlinkVRFUpgrades} from "../../src/ChainlinkVRFUpgrades.sol";

// forge script script/polygon/ChainlinkVRFUpgrades.s.sol:SubscriptionConsumerUpgradesScript --rpc-url https://polygon-amoy.g.alchemy.com/v2/vkZ5WPCV0qB9Gye9sajMsn9YhdSl7Shy --private-key $WEB3GAMING_PRIVATE_KEY --broadcast --verify --etherscan-api-key 3B5VHH6EPJ17CQGFIHDT3BU5V4UNHIEVQB

/**
== Logs ==
  Deploying contracts with the account: 0x355eb1c3D6dF0642b3abe2785e821C574837C79f
  ChainlinkVRFUpgrades Proxy deployed to: 0x5b0B1Cf4e1Fd328945b5473E54e3Bd7afEAFd5C2
  ChainlinkVRFUpgrades Implementation deployed to: 0xE653b4530989Df60efeb6210C36d57290a442A0A
  ChainlinkVRFUpgrades Owner set to: 0x355eb1c3D6dF0642b3abe2785e821C574837C79f

  cast call --rpc-url https://polygon-amoy.g.alchemy.com/v2/vkZ5WPCV0qB9Gye9sajMsn9YhdSl7Shy 0x5b0B1Cf4e1Fd328945b5473E54e3Bd7afEAFd5C2 "version()(uint256)" 
 */

contract SubscriptionConsumerUpgradesScript is Script {
    function run() public {
     // 获取部署者私钥
        string memory privateKey = vm.envString("WEB3GAMING_PRIVATE_KEY");
        uint256 deployerPrivateKey = vm.parseUint(string.concat("0x", privateKey));
        address deployerAddress = vm.addr(deployerPrivateKey);
        address proxyAddress = 0x5b0B1Cf4e1Fd328945b5473E54e3Bd7afEAFd5C2;
        console.log("Deploying contracts with the account: %s", deployerAddress);

        // 部署合约
        vm.startBroadcast(deployerPrivateKey);
        
        Upgrades.upgradeProxy(
            proxyAddress,
            "ChainlinkVRFUpgrades.sol:ChainlinkVRFUpgrades",
            ""
        );

        console.log("ChainlinkVRFUpgrades Proxy deployed to:", proxyAddress);
        address implementation = Upgrades.getImplementationAddress(proxyAddress);
        console.log("ChainlinkVRFUpgrades Implementation deployed to:", implementation);
        console.log("ChainlinkVRFUpgrades Owner set to:", deployerAddress);

        vm.stopBroadcast();


    }
}