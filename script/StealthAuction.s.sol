// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";

import {Constants} from "./base/Constants.sol";
import {StealthAuction} from "../src/StealthAuction.sol";
import {HookMiner} from "v4-periphery/src/utils/HookMiner.sol";

/// @notice Mines the address and deploys the StealthAuction.sol Hook contract
contract StealthAuctionScript is Script, Constants {
    function setUp() public {}

    function run() public returns (StealthAuction auctionHook) {
        console.log("Deploying StealthAuction Hook...");
        console.log("Chain ID:", block.chainid);
        console.log("PoolManager:", address(POOLMANAGER));

        // Hook contracts must have specific flags encoded in the address
        // Complete hook coverage: afterInitialize, beforeAddLiquidity, beforeSwap, afterSwap
        uint160 flags = uint160(
            Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG | 
            Hooks.AFTER_INITIALIZE_FLAG | Hooks.BEFORE_ADD_LIQUIDITY_FLAG
        );

        // Mine a salt that will produce a hook address with the correct flags
        bytes memory constructorArgs = abi.encode(POOLMANAGER);
        (address hookAddress, bytes32 salt) = HookMiner.find(
            CREATE2_DEPLOYER,
            flags,
            type(StealthAuction).creationCode,
            constructorArgs
        );

        console.log("Found hook address:", hookAddress);
        console.log("Salt:", vm.toString(salt));

        // Deploy the hook using CREATE2
        vm.startBroadcast();
        auctionHook = new StealthAuction{salt: salt}(IPoolManager(POOLMANAGER));
        vm.stopBroadcast();

        require(address(auctionHook) == hookAddress, "StealthAuctionScript: hook address mismatch");

        console.log("StealthAuction deployed at:", address(auctionHook));
        console.log("Hook permissions:");
        console.log("  afterInitialize:", auctionHook.getHookPermissions().afterInitialize);
        console.log("  beforeAddLiquidity:", auctionHook.getHookPermissions().beforeAddLiquidity);
        console.log("  beforeSwap:", auctionHook.getHookPermissions().beforeSwap);
        console.log("  afterSwap:", auctionHook.getHookPermissions().afterSwap);
        
        return auctionHook;
    }
}
