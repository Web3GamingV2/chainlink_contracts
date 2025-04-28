// SPDX-License-Identifier: MIT
// An example of a consumer contract that directly pays for each request.
pragma solidity ^0.8.19;

interface IChainlinkVRFCellee {
    function receiveRandomWords(uint256[] memory randomWords) external;
}