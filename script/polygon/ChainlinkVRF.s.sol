// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {ChainlinkVRF} from "../../src/ChainlinkVRF.sol";

// forge script script/polygon/ChainlinkVRF.s.sol:SubscriptionConsumerScript --rpc-url https://polygon-amoy.g.alchemy.com/v2/vkZ5WPCV0qB9Gye9sajMsn9YhdSl7Shy --private-key $WEB3GAMING_PRIVATE_KEY --broadcast --verify --etherscan-api-key 3B5VHH6EPJ17CQGFIHDT3BU5V4UNHIEVQB
// == Logs ==
//   Deploying contracts with the account: 0x355eb1c3D6dF0642b3abe2785e821C574837C79f
//   ChainlinkVRF Proxy deployed to: 0x9eE02875768A0a82C29F8244596d661d45294202
//   ChainlinkVRF Implementation deployed to: 0xE6720fD40718318CdF998bb4C4C9b539E32Bf618
//   ChainlinkVRF Owner set to: 0x355eb1c3D6dF0642b3abe2785e821C574837C79f
// cast send --rpc-url https://polygon-amoy.g.alchemy.com/v2/vkZ5WPCV0qB9Gye9sajMsn9YhdSl7Shy --private-key $WEB3GAMING_PRIVATE_KEY 0x9eE02875768A0a82C29F8244596d661d45294202 "requestRandomWords(bool,uint32,uint16,uint32)(uint256)" false 2 3 300000
// cast call --rpc-url https://polygon-amoy.g.alchemy.com/v2/vkZ5WPCV0qB9Gye9sajMsn9YhdSl7Shy 0x5b0B1Cf4e1Fd328945b5473E54e3Bd7afEAFd5C2 "getRequestStatus(uint256)(bool,uint256[],address)" 74404205751367171453680425166754391776173647567223678025261793795674402599589
// cast call --rpc-url https://polygon-amoy.g.alchemy.com/v2/vkZ5WPCV0qB9Gye9sajMsn9YhdSl7Shy 0x5b0B1Cf4e1Fd328945b5473E54e3Bd7afEAFd5C2 "allowedCallers(address)(bool)" 0x19658E697488012611Aa9328D8a2fe05922141b4
// cast send --rpc-url https://polygon-amoy.g.alchemy.com/v2/vkZ5WPCV0qB9Gye9sajMsn9YhdSl7Shy --private-key $WEB3GAMING_PRIVATE_KEY 0x5b0B1Cf4e1Fd328945b5473E54e3Bd7afEAFd5C2 "addCaller(address)" 0x19658E697488012611Aa9328D8a2fe05922141b4

contract SubscriptionConsumerScript is Script {
    function run() external {
        // 获取部署者私钥
        string memory privateKey = vm.envString("WEB3GAMING_PRIVATE_KEY");
        uint256 deployerPrivateKey = vm.parseUint(string.concat("0x", privateKey));
        address deployerAddress = vm.addr(deployerPrivateKey);
        console.log("Deploying contracts with the account: %s", deployerAddress);
        // polygon amoy
        uint256 subId = 34100889752165546479467829582008548184001830400771877916881392854243413183315;
        bytes32 keyHash = 0x816bedba8a50b294e5cbd47842baf240c2385f2eaf719edbd4f250a137a8c899;
        address vrfCoordinator = 0x343300b5d84D444B2ADc9116FEF1bED02BE49Cf2;
        address initialOwner = deployerAddress;
        vm.startBroadcast(deployerPrivateKey);
        // 部署合约
        // ChainlinkVRF consumer = new ChainlinkVRF(initialOwner, vrfCoordinator, subId, keyHash);
         bytes memory initData = abi.encodeWithSelector(
            ChainlinkVRF.initialize.selector,
            initialOwner,
            vrfCoordinator,
            subId,
            keyHash
        );

         address proxy = Upgrades.deployUUPSProxy(
            "ChainlinkVRF.sol:ChainlinkVRF", // 合约文件名:合约名
            initData
        );
       // --- 输出结果 ---
        console.log("ChainlinkVRF Proxy deployed to:", proxy);
        address implementation = Upgrades.getImplementationAddress(proxy);
        console.log("ChainlinkVRF Implementation deployed to:", implementation);
        console.log("ChainlinkVRF Owner set to:", initialOwner);
        vm.stopBroadcast();
    }
}
