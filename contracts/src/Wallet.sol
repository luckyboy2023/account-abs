// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.24;
import "../struct/UserOperation.sol";
import "../interface/IWallet.sol";
import "../library/UserOperationLib.sol";
import "hardhat/console.sol";

contract Wallet is IWallet {
    using UserOperationLib for UserOperation;
    uint256 private nonce = 0;
    address private owner = address(0);

    constructor(){
        owner = msg.sender;
    } 

    function executeOp(UserOperation calldata op) external payable{
        uint256 preGas = gasleft();
        require(nonce == op.nonce, "invalid nonce value");
        nonce++;

        require(owner == op.getAddressFromSignature(), "invalid msg sender");

        uint256 gasRemain = op.gas - (preGas - gasleft());
        (bool success, bytes memory data) = op.to.call{value: op.value, gas: gasRemain}(op.data);
        require(success, string(data));
        require(preGas - gasleft() <= op.gas,  "invalid gas use");
    }

    receive() external payable {
        // 处理收到的以太币
    }
}