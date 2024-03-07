// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.24;

import "../struct/UserOperation.sol";
import "../library/UserOperationLib.sol";
import "../interface/IWallet.sol";

contract EntryPoint {
    enum EthOperation {
        Deposit,
        Withdraw
    }

    event ETHChanged (
        EthOperation eth_operation,
        address from,
        address to,
        uint256 amount
    );

    struct walletOwner {
        address payable owner;
        uint256 amount;
    }

    using UserOperationLib for UserOperation;
    mapping(address => walletOwner) public accounts;
    function getPerGasFee(uint256 maxFeePerGas, uint256 maxPriorityFeePerGas) internal view returns (uint256) {
        if (maxPriorityFeePerGas == maxFeePerGas) {
            return maxPriorityFeePerGas;
        }
        return min(maxPriorityFeePerGas + block.basefee, maxFeePerGas);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b? a: b;
    }

    function handleOp(UserOperation calldata op) external {
        uint256 beforeGas = gasleft();
        uint256 perGasPrice = getPerGasFee(op.maxFeePerGas, op.maxPriorityFeePerGas);
        require(accounts[op.sender].amount >= op.gas * perGasPrice, "not enough eth");
        try 
            IWallet(op.sender).executeOp{
                    gas: op.gas
            }(op) 
        {}
        catch {
            revert("executeOp failed");
        }
        uint256 afterGas =  gasleft();
        require((beforeGas - afterGas) <= op.gas, "gas use out of range");
        accounts[op.sender].amount -= (beforeGas - afterGas) * perGasPrice;
        payable(msg.sender).transfer((beforeGas - afterGas) * perGasPrice);
    }

    function deposit(address wallet) external payable {
        emit ETHChanged(EthOperation.Withdraw, msg.sender, wallet, msg.value);
        if (accounts[wallet].owner == address(0)) {
            accounts[wallet] = walletOwner(payable(msg.sender), msg.value);
        } else {
            accounts[wallet].amount += msg.value;
        }
    }

    function withdrawTo(address payable wallet) external {
        require(accounts[wallet].owner == msg.sender, "not owner");
        accounts[wallet].owner.transfer(accounts[wallet].amount);
        emit ETHChanged(EthOperation.Withdraw, wallet, msg.sender, accounts[wallet].amount);
        accounts[wallet].amount = 0;
    }
}