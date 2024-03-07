// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "../struct/UserOperation.sol";

library UserOperationLib {
    function getSignHash(UserOperation calldata op) internal pure returns (bytes32) {
        return keccak256(abi.encode(op.sender, op.to, op.data, op.value, op.gas, op.nonce));
    }

    function getAddressFromSignature(UserOperation calldata op) internal pure returns (address) {
        bytes32 hash = getSignHash(op);
        bytes32 r;
        bytes32 s;
        uint8 v;
        bytes memory signature = op.signature;
        assembly {
            r := mload(add(signature, add(0x00, 0x20)))
            s := mload(add(signature, add(0x20, 0x20)))
            v := byte(0, mload(add(signature, add(0x40, 0x20))))
        }
        return ecrecover(hash, v, r, s);
    }
}