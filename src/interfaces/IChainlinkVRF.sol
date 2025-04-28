// SPDX-License-Identifier: MIT
// An example of a consumer contract that directly pays for each request.
pragma solidity ^0.8.19;

interface IChainlinkVRF {
    function requestRandomWords(
        bool enableNativePayment, 
        uint32 numWords,
        uint16 requestConfirmations,
        uint32 callbackGasLimit, address callee) external returns (uint256 requestId);
    function getRequestStatus(uint256 _requestId)
        external
        returns (bool fulfilled, uint256[] memory randomWords, address callee);
}