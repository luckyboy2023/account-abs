import { ethers } from "hardhat";
import {AbiCoder, keccak256, recoverAddress, SigningKey, Interface} from "ethers";
import walletCont from "../artifacts/contracts/src/Wallet.sol/Wallet.json";
import LockCont from "../artifacts/contracts/Lock.sol/Lock.json";
import EntryPointCont from "../artifacts/contracts/src/EntryPoint.sol/EntryPoint.json";
import {time, loadFixture,} from "@nomicfoundation/hardhat-toolbox/network-helpers";

describe("wallet", function(){
    async function deployWalletFixture() {
        const [owner] = await ethers.getSigners();
        const optionWallet = new ethers.ContractFactory(
            walletCont.abi, walletCont.bytecode, owner);
        const wallet = await optionWallet.deploy();
        return {owner, wallet};
    }

    async function deployOneYearLockFixture() {
        const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
        const ONE_GWEI = 1_000_000_000;
    
        const lockedAmount = ONE_GWEI;
        const unlockTime = (await time.latest());
    
        // Contracts are deployed using the first signer/account by default
        const [owner, otherAccount] = await ethers.getSigners();
    
        const Lock = await ethers.getContractFactory("Lock");
        const lock = await Lock.deploy(unlockTime, { value: lockedAmount });
    
        return { lock, unlockTime, lockedAmount, owner, otherAccount };
    }

    async function deployEntryPointFixture() {
        const [owner] = await ethers.getSigners();
        const optionEntryPoint = new ethers.ContractFactory(
            EntryPointCont.abi, EntryPointCont.bytecode, owner);
        const entryPoint = await optionEntryPoint.deploy();
        return {owner, entryPoint};
    }
    
    describe("executeOp", function(){
        it("execute lock op", async function () {
            const { owner, wallet } = await loadFixture(deployWalletFixture);
            const { lock } = await loadFixture(deployOneYearLockFixture);

            let iface = new Interface(LockCont.abi);
            const rawData = await iface.encodeFunctionData("withdraw", []);
            let execData = {
                sender: await wallet.getAddress(),
                to: await lock.getAddress(),
                data: rawData,
                value: 0,
                gas: 600000,
                nonce: 0,
                maxFeePerGas: 21000,
                maxPriorityFeePerGas: 100,
            };

            const abiCoder = new AbiCoder();
            const encExecData = await abiCoder.encode(["address","address", "bytes", "uint256", "uint256", "uint256"], 
                [execData.sender, execData.to, execData.data, execData.value, execData.gas, execData.nonce]);
            
            const signingKey = new SigningKey(hre.network.config.accounts[0].privateKey);
            const signature = await signingKey.sign(await keccak256(encExecData)).serialized;
            await owner.sendTransaction({
                to: await lock.getAddress(),
                value: await ethers.parseEther("1.0"), // Sends exactly 1.0 ether
            });
            execData.signature = signature;
            await lock.connect(owner).changeOwner(wallet.getAddress());
            const to_balance1 = await ethers.provider.getBalance(wallet.getAddress());
            let res = await wallet.connect(owner).executeOp(execData);
            const to_balance2 = await ethers.provider.getBalance(wallet.getAddress());
            console.log(to_balance1);
            console.log(to_balance2);
        });

        it("entrypoint handle op", async function () {
            const { owner, wallet } = await loadFixture(deployWalletFixture);
            const { lock } = await loadFixture(deployOneYearLockFixture);
            const { entryPoint } = await loadFixture(deployEntryPointFixture);

            let iface = new Interface(LockCont.abi);
            const rawData = await iface.encodeFunctionData("withdraw", []);
            let execData = {
                sender: await wallet.getAddress(),
                to: await lock.getAddress(),
                data: rawData,
                value: 0,
                gas: 600000,
                nonce: 0,
                maxFeePerGas: 21000,
                maxPriorityFeePerGas: 100,
            };

            const abiCoder = new AbiCoder();
            const encExecData = await abiCoder.encode(["address","address", "bytes", "uint256", "uint256", "uint256"], 
                [execData.sender, execData.to, execData.data, execData.value, execData.gas, execData.nonce]);
            
            const signingKey = new SigningKey(hre.network.config.accounts[0].privateKey);
            const signature = await signingKey.sign(await keccak256(encExecData)).serialized;
            await owner.sendTransaction({
                to: await lock.getAddress(),
                value: await ethers.parseEther("1.0"), // Sends exactly 1.0 ether
            });
            execData.signature = signature;
            await lock.connect(owner).changeOwner(wallet.getAddress());
            await entryPoint.connect(owner).deposit(wallet.getAddress(), { value:  await ethers.parseEther("1.0") });
            const to_balance1 = await ethers.provider.getBalance(entryPoint.getAddress());
            await entryPoint.connect(owner).handleOp(execData);
            const to_balance2 = await ethers.provider.getBalance(entryPoint.getAddress());
            console.log(to_balance1);
            console.log(to_balance2);
        });
    })
})