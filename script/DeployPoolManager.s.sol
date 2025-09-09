// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {PoolManager} from "@uniswap/v4-core/src/PoolManager.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";

contract DeployPoolManagerScript is Script {
    function setUp() public {}

    function run() public returns (IPoolManager poolManager) {
        console.log("Deploying PoolManager...");
        console.log("Chain ID:", block.chainid);

        vm.startBroadcast();
        poolManager = IPoolManager(address(new PoolManager(address(0))));
        vm.stopBroadcast();

        console.log("PoolManager deployed at:", address(poolManager));
        
        return poolManager;
    }
}