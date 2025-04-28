// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ChainlinkVRF} from "../../src/ChainlinkVRF.sol";

/**
== Logs ==
  Deploying contracts with the account: 0x355eb1c3D6dF0642b3abe2785e821C574837C79f
  ChainlinkVRF Implementation deployed to: 0x2467108995a7579BB95d6CA46a639589f8E1B8Ae
  ChainlinkVRF Owner set to: 0x355eb1c3D6dF0642b3abe2785e821C574837C79f
 */

// forge script script/polygon/ChainlinkVRF.s.sol:SubscriptionConsumerScript --rpc-url https://polygon-amoy.g.alchemy.com/v2/vkZ5WPCV0qB9Gye9sajMsn9YhdSl7Shy --private-key $WEB3GAMING_PRIVATE_KEY --broadcast --verify --etherscan-api-key 3B5VHH6EPJ17CQGFIHDT3BU5V4UNHIEVQB
// cast send --rpc-url https://polygon-amoy.g.alchemy.com/v2/vkZ5WPCV0qB9Gye9sajMsn9YhdSl7Shy --private-key $WEB3GAMING_PRIVATE_KEY 0x2467108995a7579bb95d6ca46a639589f8e1b8ae "requestRandomWords(bool,uint32,uint16,uint32,address)(uint256)" false 2 3 200000 0xBd32Bec48cE1d57e2980e1c6Cf2FFF085563171c
// cast call --rpc-url https://polygon-amoy.g.alchemy.com/v2/vkZ5WPCV0qB9Gye9sajMsn9YhdSl7Shy 0x5b0B1Cf4e1Fd328945b5473E54e3Bd7afEAFd5C2 "getRequestStatus(uint256)(bool,uint256[],address)" 74404205751367171453680425166754391776173647567223678025261793795674402599589
// cast call --rpc-url https://polygon-amoy.g.alchemy.com/v2/vkZ5WPCV0qB9Gye9sajMsn9YhdSl7Shy 0x5b0B1Cf4e1Fd328945b5473E54e3Bd7afEAFd5C2 "allowedCallers(address)(bool)" 0x355eb1c3D6dF0642b3abe2785e821C574837C79f
// cast send --rpc-url https://polygon-amoy.g.alchemy.com/v2/vkZ5WPCV0qB9Gye9sajMsn9YhdSl7Shy --private-key $WEB3GAMING_PRIVATE_KEY 0x5b0B1Cf4e1Fd328945b5473E54e3Bd7afEAFd5C2 "addCaller(address)" 0xBd32Bec48cE1d57e2980e1c6Cf2FFF085563171c

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
        ChainlinkVRF consumer = new ChainlinkVRF(initialOwner, initialOwner, vrfCoordinator, subId, keyHash);
       // --- 输出结果 ---
        console.log("ChainlinkVRF Implementation deployed to:", address(consumer));
        console.log("ChainlinkVRF Owner set to:", initialOwner);
        vm.stopBroadcast();
    }
}