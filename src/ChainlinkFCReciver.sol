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

    function requestFunction(
        uint64 subscriptionId,
        string[] calldata args,
        uint32 callbackGasLimit
    ) external {
        bytes32 requestId = fc.sendRequest(
            subscriptionId,
            args,
            source,
            callbackGasLimit,
            address(this)
        );
        emit RequestSent(requestId);
    }

    function receiveFunctionResponse(bytes32 _requestId,bytes memory _response) external {
        emit ResponseFulfilled(_requestId,_response);
    }
}