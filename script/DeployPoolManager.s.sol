// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {PoolManager} from "@uniswap/v4-core/src/PoolManager.sol";

/// @notice Deploy PoolManager for testing
contract DeployPoolManagerScript is Script {
    function setUp() public {}

    function run() public returns (PoolManager poolManager) {
        console.log("Deploying PoolManager...");
        console.log("Deployer:", msg.sender);

        vm.startBroadcast();
        
        // Deploy PoolManager with deployer as owner
        poolManager = new PoolManager(msg.sender);
        
        vm.stopBroadcast();

        console.log("PoolManager deployed at:", address(poolManager));
        return poolManager;
    }
}
