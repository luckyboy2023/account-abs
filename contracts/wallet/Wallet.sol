// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.24;
import "hardhat/console.sol";

struct UserOperation {
    address to;
    bytes data;
    uint256 value;
    uint256 gas;
    uint256 nonce;
    bytes signature;
}

contract Wallet {
    uint256 private nonce = 0;

    function executeOp(UserOperation calldata op) external payable{
        uint256 preGas = gasleft();
        require(nonce == op.nonce, "invalid nonce value");
        nonce++;

        bytes32 hash = keccak256(abi.encode(op.to, op.data, op.value, op.gas, op.nonce));
        bytes32 r;
        bytes32 s;
        uint8 v;
        bytes memory signature = op.signature;
        assembly {
            r := mload(add(signature, add(0x00, 0x20)))
            s := mload(add(signature, add(0x20, 0x20)))
            v := byte(0, mload(add(signature, add(0x40, 0x20))))
        }
        require(msg.sender == ecrecover(hash, v, r, s), "invalid msg sender");

        uint256 gasRemain = op.gas - (preGas - gasleft());
        (bool success, bytes memory data) = op.to.call{value: op.value, gas: gasRemain}(op.data);
        require(success, string(data));
        require(preGas - gasleft() <= op.gas,  "invalid gas use");
    }

    receive() external payable {
        // 处理收到的以太币
    }
}