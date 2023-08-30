// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract FundoorUtils {
    function timenow() external view returns (uint) {
        return block.timestamp;
    }
}
 