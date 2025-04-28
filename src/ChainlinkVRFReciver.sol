// SPDX-License-Identifier: MIT
// An example of a consumer contract that directly pays for each request.
pragma solidity ^0.8.19;

import "./interfaces/IChainlinkVRFCellee.sol";

contract ChainlinkVRFReciver is IChainlinkVRFCellee {

    event RandomWordsReceived(address indexed caller, uint256[] randomWords);

    uint256[] public randomWords;
    function revicerRandomWords(uint256[] memory _randomWords) external override {
        randomWords = _randomWords;
        emit RandomWordsReceived(msg.sender, _randomWords); // Emit an event to indicate the rando
    }
}
