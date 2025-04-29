// SPDX-License-Identifier: MIT
// An example of a consumer contract that directly pays for each request.
pragma solidity ^0.8.19;

import { ChainlinkVRF } from "./ChainlinkVRF.sol";

/// @custom:oz-upgrades-from ChainlinkVRF
contract ChainlinkVRFUpgrades is ChainlinkVRF {
    function version() external virtual pure returns (uint256) {
        return 8;
    }
}
