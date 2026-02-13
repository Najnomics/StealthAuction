// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {StealthAuction} from "../src/StealthAuction.sol";
import {StealthAuctionToken} from "../src/StealthAuctionToken.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";

/// @title Verify Deployment Script
/// @notice Verifies that all contracts exist and are accessible on Sepolia
contract VerifyDeployment is Script {
    using PoolIdLibrary for PoolKey;

    function run() external view {
        console.log("=== Verifying StealthAuction Deployment on Sepolia ===");
        console.log("Chain ID:", block.chainid);
        
        // Load addresses from environment
        address hook = vm.envAddress("STEALTH_AUCTION_HOOK");
        address auctionToken = vm.envAddress("AUCTION_TOKEN");
        address poolManager = vm.envAddress("POOL_MANAGER");
        address token0 = vm.envAddress("TOKEN0");
        address token1 = vm.envAddress("TOKEN1");
        
        console.log("\n--- Contract Addresses ---");
        console.log("Hook:", hook);
        console.log("Auction Token:", auctionToken);
        console.log("Pool Manager:", poolManager);
        console.log("Token0:", token0);
        console.log("Token1:", token1);
        
        // Verify contracts exist
        console.log("\n--- Contract Verification ---");
        _verifyContract(hook, "Hook");
        _verifyContract(auctionToken, "Auction Token");
        _verifyContract(poolManager, "Pool Manager");
        _verifyContract(token0, "Token0");
        _verifyContract(token1, "Token1");
        
        // Verify hook configuration
        console.log("\n--- Hook Configuration ---");
        try StealthAuction(hook).poolManager() returns (IPoolManager pm) {
            console.log("Hook PoolManager:", address(pm));
            if (address(pm) == poolManager) {
                console.log("[OK] Hook correctly configured with PoolManager");
            } else {
                console.log("[ERROR] Hook PoolManager mismatch!");
            }
        } catch {
            console.log("[ERROR] Could not read hook PoolManager");
        }
        
        // Verify pool configuration
        console.log("\n--- Pool Configuration ---");
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(hook)
        });
        PoolId poolId = key.toId();
        console.log("Pool ID:", vm.toString(uint256(PoolId.unwrap(poolId))));
        console.log("Note: Pool initialization status cannot be verified without calling initialize()");
        
        // Verify token balances
        console.log("\n--- Token Balances (Deployer) ---");
        address deployer = msg.sender;
        try StealthAuctionToken(token0).balanceOf(deployer) returns (uint256 bal) {
            console.log("Token0 balance:", bal);
        } catch {
            console.log("[ERROR] Could not read Token0 balance");
        }
        
        try StealthAuctionToken(token1).balanceOf(deployer) returns (uint256 bal) {
            console.log("Token1 balance:", bal);
        } catch {
            console.log("[ERROR] Could not read Token1 balance");
        }
        
        try StealthAuctionToken(auctionToken).balanceOf(deployer) returns (uint256 bal) {
            console.log("AuctionToken balance:", bal);
        } catch {
            console.log("[ERROR] Could not read AuctionToken balance");
        }
        
        console.log("\n=== Verification Complete ===");
    }
    
    function _verifyContract(address addr, string memory name) internal view {
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(addr)
        }
        
        if (codeSize > 0) {
            console.log("[OK] %s exists (code size: %s bytes)", name, codeSize);
        } else {
            console.log("[ERROR] %s does NOT exist at address", name);
        }
    }
}
