// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {ChainlinkVRF} from "../../src/ChainlinkVRF.sol";

// forge script script/ChainlinkVRF.s.sol:SubscriptionConsumerScript --rpc-url https://polygon-amoy.g.alchemy.com/v2/vkZ5WPCV0qB9Gye9sajMsn9YhdSl7Shy --private-key $WEB3GAMING_PRIVATE_KEY --broadcast --verify --etherscan-api-key 3B5VHH6EPJ17CQGFIHDT3BU5V4UNHIEVQB
// == Logs ==
//   Deploying contracts with the account: 0x355eb1c3D6dF0642b3abe2785e821C574837C79f
//   GettingStartedVRFConsumer address: 0x1ab158924321143028a35EfF3F229B48a057C726
//   Contract owner: 0x355eb1c3D6dF0642b3abe2785e821C574837C79f
//   Is deployer owner? true
// cast send --rpc-url https://polygon-amoy.g.alchemy.com/v2/vkZ5WPCV0qB9Gye9sajMsn9YhdSl7Shy --private-key $WEB3GAMING_PRIVATE_KEY 0x1ab158924321143028a35EfF3F229B48a057C726 "requestRandomWords(bool)(uint256)" false
// cast call --rpc-url https://polygon-amoy.g.alchemy.com/v2/vkZ5WPCV0qB9Gye9sajMsn9YhdSl7Shy 0x1ab158924321143028a35EfF3F229B48a057C726 "lastRequestId()" 
// cast call --rpc-url https://polygon-amoy.g.alchemy.com/v2/vkZ5WPCV0qB9Gye9sajMsn9YhdSl7Shy 0x1ab158924321143028a35EfF3F229B48a057C726 "getRequestStatus(uint256)(bool,uint256[])" 0xa03171da6dd4dd3c67264950fc47df28011b259f3d6bc5b8e96ed7debac8f333

contract SubscriptionConsumerScript is Script {
    function run() external {
        // 获取部署者私钥
        string memory privateKey = vm.envString("WEB3GAMING_PRIVATE_KEY");
        uint256 deployerPrivateKey = vm.parseUint(string.concat("0x", privateKey));
        address deployerAddress = vm.addr(deployerPrivateKey);
        console.log("Deploying contracts with the account: %s", deployerAddress);
        // polygon amoy
        uint256 subId = 16135761596414936982790387770436467016151339682448979040396698217123758120470;
        bytes32 keyHash = 0x816bedba8a50b294e5cbd47842baf240c2385f2eaf719edbd4f250a137a8c899;
        address vrfCoordinator = 0x343300b5d84D444B2ADc9116FEF1bED02BE49Cf2;
        address initialOwner = deployerAddress;
        vm.startBroadcast(deployerPrivateKey);
        // 部署合约
        // ChainlinkVRF consumer = new ChainlinkVRF(initialOwner, vrfCoordinator, subId, keyHash);
         bytes memory initData = abi.encodeWithSelector(
            consumer.initialize.selector,
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
