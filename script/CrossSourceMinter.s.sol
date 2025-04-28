// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";

import {CrossSourceMinter} from "../src/ccip_minter/CrossSourceMinter.sol";

// forge script script/CrossSourceMinter.s.sol:CrossSourceMinterScript --rpc-url https://polygon-amoy.g.alchemy.com/v2/vkZ5WPCV0qB9Gye9sajMsn9YhdSl7Shy --private-key $WEB3GAMING_PRIVATE_KEY --broadcast --verify --etherscan-api-key 3B5VHH6EPJ17CQGFIHDT3BU5V4UNHIEVQB
/**
 == Logs ==
  Deploying contracts with the account: 0x355eb1c3D6dF0642b3abe2785e821C574837C79f
  CrossSourceMinter address: 0xf725cca7A9Fec059902ccEf9392a1980c2417aB0
  Contract owner: 0x355eb1c3D6dF0642b3abe2785e821C574837C79f
  cast send --rpc-url https://polygon-amoy.g.alchemy.com/v2/vkZ5WPCV0qB9Gye9sajMsn9YhdSl7Shy --private-key $WEB3GAMING_PRIVATE_KEY 0xf725cca7A9Fec059902ccEf9392a1980c2417aB0 "mintOnSepolia()"
  cast call --rpc-url https://polygon-amoy.g.alchemy.com/v2/vkZ5WPCV0qB9Gye9sajMsn9YhdSl7Shy --private-key $WEB3GAMING_PRIVATE_KEY 0xf725cca7A9Fec059902ccEf9392a1980c2417aB0 "linkBalance(address)(uint256)" 0xf725cca7A9Fec059902ccEf9392a1980c2417aB0
 */
contract CrossSourceMinterScript is Script {
    function run() external {
        // 获取部署者私钥
        string memory privateKey = vm.envString("WEB3GAMING_PRIVATE_KEY");
        uint256 deployerPrivateKey = vm.parseUint(string.concat("0x", privateKey));
        address deployerAddress = vm.addr(deployerPrivateKey);
        console.log("Deploying contracts with the account: %s", deployerAddress);
        address destMinterAddress = 0x6a1D2A1F13cfd9b07CDaE6C703c87A78A19FC809;
        vm.startBroadcast(deployerPrivateKey);
        // 部署合约
        CrossSourceMinter consumer = new CrossSourceMinter(destMinterAddress);
        console.log("CrossSourceMinter address: %s", address(consumer));
        console.log("Contract owner: %s", deployerAddress);
        vm.stopBroadcast();
    }
}
