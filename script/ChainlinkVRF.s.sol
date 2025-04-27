// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {SubscriptionConsumer} from "../src/ChainlinkVRF.sol";

// forge script script/ChainlinkVRF.s.sol:SubscriptionConsumerScript --rpc-url https://polygon-amoy.g.alchemy.com/v2/vkZ5WPCV0qB9Gye9sajMsn9YhdSl7Shy --private-key $WEB3GAMING_PRIVATE_KEY --broadcast --verify --etherscan-api-key 3B5VHH6EPJ17CQGFIHDT3BU5V4UNHIEVQB
// == Logs ==
//   Deploying contracts with the account: 0x355eb1c3D6dF0642b3abe2785e821C574837C79f
//   GettingStartedVRFConsumer address: 0x1ab158924321143028a35EfF3F229B48a057C726
//   Contract owner: 0x355eb1c3D6dF0642b3abe2785e821C574837C79f
//   Is deployer owner? true
// cast send --rpc-url https://polygon-amoy.g.alchemy.com/v2/vkZ5WPCV0qB9Gye9sajMsn9YhdSl7Shy --private-key $WEB3GAMING_PRIVATE_KEY 0x1ab158924321143028a35EfF3F229B48a057C726 "requestRandomWords(bool)(uint256)" false
// cast call --rpc-url https://polygon-amoy.g.alchemy.com/v2/vkZ5WPCV0qB9Gye9sajMsn9YhdSl7Shy 0x1ab158924321143028a35EfF3F229B48a057C726 "lastRequestId()" 
// cast call --rpc-url https://polygon-amoy.g.alchemy.com/v2/vkZ5WPCV0qB9Gye9sajMsn9YhdSl7Shy 0x1ab158924321143028a35EfF3F229B48a057C726 "getRequestStatus(uint256)(bool,uint256[])" 0xa03171da6dd4dd3c67264950fc47df28011b259f3d6bc5b8e96ed7debac8f333

// forge script script/ChainlinkVRF.s.sol:SubscriptionConsumerScript --rpc-url $WEB3GAMING_ALCHEMY_RPC_URL --private-key $WEB3GAMING_PRIVATE_KEY --broadcast --verify --etherscan-api-key $WEB3GAMING_ETHERSCAN_API_KEY
/**
 * == Logs ==
 *   Deploying contracts with the account: 0x355eb1c3D6dF0642b3abe2785e821C574837C79f
 *   GettingStartedVRFConsumer address: 0x53A46a9c858488F37ed9EdFe29DA07b01ab0702B
 *   Contract owner: 0x355eb1c3D6dF0642b3abe2785e821C574837C79f
 *   Is deployer owner? true
 *   cast send --rpc-url $WEB3GAMING_ALCHEMY_RPC_URL --private-key $WEB3GAMING_PRIVATE_KEY 0x53A46a9c858488F37ed9EdFe29DA07b01ab0702B "requestRandomWords(bool)(uint256)" false
 *   cast call --rpc-url $WEB3GAMING_ALCHEMY_RPC_URL 0x53A46a9c858488F37ed9EdFe29DA07b01ab0702B "lastRequestId()" 
 *   cast call --rpc-url $WEB3GAMING_ALCHEMY_RPC_URL 0x53A46a9c858488F37ed9EdFe29DA07b01ab0702B "s_requests(uint256)(bool,bool,uint256[])" 0x7fdf8fcc4df781a2aa305d6af1884a1b3dbf38c1d309576b533397793c8c14b0
 *   cast call --rpc-url $WEB3GAMING_ALCHEMY_RPC_URL 0x53A46a9c858488F37ed9EdFe29DA07b01ab0702B "getRequestStatus(uint256)(bool,uint256[])" 0x7fdf8fcc4df781a2aa305d6af1884a1b3dbf38c1d309576b533397793c8c14b0
 */
contract SubscriptionConsumerScript is Script {
    function run() external {
        // 获取部署者私钥
        string memory privateKey = vm.envString("WEB3GAMING_PRIVATE_KEY");
        uint256 deployerPrivateKey = vm.parseUint(string.concat("0x", privateKey));
        address deployerAddress = vm.addr(deployerPrivateKey);
        console.log("Deploying contracts with the account: %s", deployerAddress);
        // sepolia
        // uint256 subId = 79032630712985800958728562301714780717501108602871462594898701084708454825803;
        // bytes32 keyHash = 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;
        // address vrfCoordinator = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B
        // polygon amoy
        uint256 subId = 16135761596414936982790387770436467016151339682448979040396698217123758120470;
        bytes32 keyHash = 0x816bedba8a50b294e5cbd47842baf240c2385f2eaf719edbd4f250a137a8c899;
        address vrfCoordinator = 0x343300b5d84D444B2ADc9116FEF1bED02BE49Cf2;
        vm.startBroadcast(deployerPrivateKey);
        // 部署合约
        SubscriptionConsumer consumer = new SubscriptionConsumer(vrfCoordinator, subId, keyHash);
        console.log("GettingStartedVRFConsumer address: %s", address(consumer));
        console.log("Contract owner: %s", consumer.owner());
        console.log("Is deployer owner? %s", consumer.owner() == deployerAddress);
        vm.stopBroadcast();
    }
}
