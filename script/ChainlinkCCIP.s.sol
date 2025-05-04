// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {CrossCcip} from "../src/ccip/Ccip.sol";

/**
 *  发送端 + 接收端 同时部署
 *  发送端: forge script script/ChainlinkCCIP.s.sol:CrossCcipScript --rpc-url https://polygon-amoy.g.alchemy.com/v2/vkZ5WPCV0qB9Gye9sajMsn9YhdSl7Shy --private-key $WEB3GAMING_PRIVATE_KEY --broadcast --verify --etherscan-api-key 3B5VHH6EPJ17CQGFIHDT3BU5V4UNHIEVQB
 *  接收端: forge script script/ChainlinkCCIP.s.sol:CrossCcipScript --rpc-url $WEB3GAMING_ALCHEMY_RPC_URL --private-key $WEB3GAMING_PRIVATE_KEY --broadcast --verify --etherscan-api-key $WEB3GAMING_ETHERSCAN_API_KEY
 *  
 *  发送端
    == Return ==
    0: address 0x63ffFaD3e84636C717B70C51cc4ad14EfEe92f02

    == Logs ==
    Deploying contracts with the account: 0x355eb1c3D6dF0642b3abe2785e821C574837C79f
    CrossCcip address: 0x63ffFaD3e84636C717B70C51cc4ad14EfEe92f02

    cast send --rpc-url https://polygon-amoy.g.alchemy.com/v2/vkZ5WPCV0qB9Gye9sajMsn9YhdSl7Shy --private-key $WEB3GAMING_PRIVATE_KEY 0x63ffFaD3e84636C717B70C51cc4ad14EfEe92f02 "sendCcip(uint64,address,address,bytes,uint256)(bytes32)" 16015286601757825753 0x4Fb05Ec634211e81a783b8B67a5575E0e21623DB 0xBd32Bec48cE1d57e2980e1c6Cf2FFF085563171c 0x6c65656c6f6e677869 980000
    cast send --rpc-url https://polygon-amoy.g.alchemy.com/v2/vkZ5WPCV0qB9Gye9sajMsn9YhdSl7Shy --private-key $WEB3GAMING_PRIVATE_KEY 0x63ffFaD3e84636C717B70C51cc4ad14EfEe92f02 "approveRouter()"

 * 
 *  接收端
   == Return ==
    0: address 0x4Fb05Ec634211e81a783b8B67a5575E0e21623DB

    == Logs ==
    Deploying contracts with the account: 0x355eb1c3D6dF0642b3abe2785e821C574837C79f
    CrossCcip address: 0x4Fb05Ec634211e81a783b8B67a5575E0e21623DB
 */
contract CrossCcipScript is Script {
    function run() external returns (address)  {
        // 获取部署者私钥
        string memory privateKey = vm.envString("WEB3GAMING_PRIVATE_KEY");
        uint256 deployerPrivateKey = vm.parseUint(string.concat("0x", privateKey));
        address deployerAddress = vm.addr(deployerPrivateKey);
        console.log("Deploying contracts with the account: %s", deployerAddress);

        // 发送端的 router 地址 (Amoy)
        address routerCCIPClient = 0x9C32fCB86BF0f4a1A8921a9Fe46de3198bb884B2;
        // 发送端的 link 地址 (Amoy)
        address linkTokenClient = 0x0Fd9e8d3aF1aaee056EB9e802c3A762a667b1904;

        // 接收端的 router 地址 (Sepolia)
        address routerCCIPReceiver = 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59;
        // 部署合约
        vm.startBroadcast(deployerPrivateKey);
        CrossCcip ccip = new CrossCcip(
            deployerAddress,
            routerCCIPClient,
            routerCCIPReceiver,
            linkTokenClient
        );
        console.log("CrossCcip address: %s", address(ccip));
        vm.stopBroadcast();
        return address(ccip);
    }
}