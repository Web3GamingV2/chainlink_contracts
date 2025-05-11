// SPDX-License-Identifier: MIT
// An example of a consumer contract that directly pays for each request.
pragma solidity ^0.8.19;

import "./interfaces/IChainlinkFCCallee.sol";
import "./interfaces/IChainlinkFC.sol"; // Import the interface

contract ChainlinkFCReciver is IChainlinkFCCallee {

    IChainlinkFC fc;

    event ResponseFulfilled(
        bytes32 indexed requestId,
        bytes response
    );

    event RequestSent(
        bytes32 indexed requestId
    );

    string source =
    "const characterId = args[0];"
    "const apiResponse = await Functions.makeHttpRequest({"
    "url: `https://swapi.info/api/people/${characterId}/`"
    "});"
    "if (apiResponse.error) {"
    "throw Error('Request failed');"
    "}"
    "const { data } = apiResponse;"
    "return Functions.encodeString(data.name);";

    constructor(address fcAddress) {
        fc = IChainlinkFC(fcAddress);
    }

    // TODO 这里把 requestId 存在后端服务后续用户通过 id 自己获取链上结果
    function requestFunction(
        uint64 subscriptionId,
        string[] calldata args,
        uint32 callbackGasLimit
    ) external returns (bytes32) {
        bytes32 s_donId = 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000;
        bytes32 requestId = fc.sendRequest(
            subscriptionId,
            s_donId,
            args,
            source,
            callbackGasLimit
        );
        emit RequestSent(requestId);
        // 查询 ResponseReceived 事件 然后根据 id 去数据库匹配结果回填 找到后代表上链成功
        return requestId;
    }

    // TODO 监听 receive 事件 然后根据 id 去数据库匹配结果回填
    function receiveFunctionResponse(bytes32 _requestId,bytes memory _response) external {
        emit ResponseFulfilled(_requestId,_response);
    }
}