// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

struct UserOperation {
    address sender;
    address to;
    bytes data;
    uint256 value;
    uint256 gas;
    uint256 maxFeePerGas;
    uint256 maxPriorityFeePerGas;
    uint256 nonce;
    bytes signature;
}