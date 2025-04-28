// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {ChainlinkVRF} from "../../src/ChainlinkVRF.sol";

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
        uint256 subId = 79032630712985800958728562301714780717501108602871462594898701084708454825803;
        bytes32 keyHash = 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;
        address vrfCoordinator = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;
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
