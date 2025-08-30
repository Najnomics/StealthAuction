// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {StealthAuctionScript} from "./StealthAuction.s.sol";
import {DeployTokensScript} from "./DeployTokens.s.sol";
import {CreatePoolAndMintLiquidityScript} from "./01_CreatePoolAndMintLiquidity.s.sol";
import {AuctionDemoScript} from "./AuctionDemo.s.sol";

/// @notice Complete deployment script for local Anvil testing
contract AnvilScript is Script {
    function setUp() public {}

    function run() public {
        console.log("=== Complete Anvil Deployment ===");
        console.log("Chain ID:", block.chainid);
        console.log("Deployer:", msg.sender);

        // Step 1: Deploy tokens
        console.log("\n1. Deploying tokens...");
        DeployTokensScript tokenScript = new DeployTokensScript();
        tokenScript.run();

        // Step 2: Deploy hook
        console.log("\n2. Deploying StealthAuction hook...");
        StealthAuctionScript hookScript = new StealthAuctionScript();
        hookScript.run();

        // Step 3: Create pool and add liquidity
        console.log("\n3. Creating pool and adding liquidity...");
        CreatePoolAndMintLiquidityScript poolScript = new CreatePoolAndMintLiquidityScript();
        poolScript.run();

        // Step 4: Run auction demo
        console.log("\n4. Running auction demo...");
        AuctionDemoScript demoScript = new AuctionDemoScript();
        demoScript.run();

        console.log("\n=== Anvil Deployment Complete ===");
        console.log("Your encrypted Dutch auction is ready!");
        console.log("Try running: forge script script/AuctionDemo.s.sol --broadcast --rpc-url $ANVIL_RPC");
    }
}
