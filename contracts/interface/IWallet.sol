// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;
import "../struct/UserOperation.sol";

interface IWallet {
    function executeOp(UserOperation calldata op) external payable;
}