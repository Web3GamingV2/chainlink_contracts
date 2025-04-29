// SPDX-License-Identifier: MIT
// An example of a consumer contract that directly pays for each request.
pragma solidity ^0.8.19;

import "./interfaces/IChainlinkVRFCellee.sol";
import "./interfaces/IChainlinkVRF.sol";


contract ChainlinkVRFReciver {

    IChainlinkVRF vrf;

    constructor(address vrfAddress) {
        vrf = IChainlinkVRF(vrfAddress);
    }

    event RandomWordsReceived(address indexed caller, uint256[] randomWords);
    event RandomWordsRequested(address indexed caller, uint256 requestId);

    // uint256[] public randomWords;
    // function revicerRandomWords(uint256[] memory _randomWords) external override {
    //     randomWords = _randomWords;
    //     emit RandomWordsReceived(msg.sender, _randomWords); // Emit an event to indicate the rando
    // }

    function requestRandomWords(
        uint32 numWords,
        uint16 requestConfirmations,
        uint32 callbackGasLimit
    ) external returns (uint256 requestId) {
        uint256 _requestId = vrf.requestRandomWords(false, numWords, requestConfirmations, callbackGasLimit);
        emit RandomWordsRequested(msg.sender, _requestId);
        return _requestId;
    }

    function getResponseRec(uint256 _requestId)
        external
        returns (uint256[] memory randomWords) {
           uint256[] memory _randomWords =  vrf.getResponse(_requestId);
           emit RandomWordsReceived(msg.sender, _randomWords);
           return _randomWords;
    }

}
