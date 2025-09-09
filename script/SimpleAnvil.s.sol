// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {PoolManager} from "@uniswap/v4-core/src/PoolManager.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolModifyLiquidityTest} from "@uniswap/v4-core/src/test/PoolModifyLiquidityTest.sol";
import {PoolSwapTest} from "@uniswap/v4-core/src/test/PoolSwapTest.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {AuctionToken} from "../src/AuctionToken.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {Constants} from "@uniswap/v4-core/src/../test/utils/Constants.sol";

/// @notice Simple deployment script for Anvil without FHE
contract SimpleAnvilScript is Script {
    address constant CREATE2_DEPLOYER = address(0x4e59b44847b379578588920cA78FbF26c0B4956C);
    
    IPoolManager manager;
    PoolModifyLiquidityTest lpRouter;
    PoolSwapTest swapRouter;
    AuctionToken token0;
    AuctionToken token1;

    function setUp() public {}

    function run() public {
        console.log("=== Simple Anvil Deployment (without FHE) ===");
        console.log("Chain ID:", block.chainid);
        
        // Step 1: Deploy PoolManager
        vm.startBroadcast();
        manager = deployPoolManager();
        console.log("PoolManager deployed at:", address(manager));

        // Step 2: Deploy tokens
        (token0, token1) = deployTokens();
        console.log("Token0 deployed at:", address(token0));
        console.log("Token1 deployed at:", address(token1));

        // Step 3: Deploy routers
        (lpRouter, swapRouter) = deployRouters(manager);
        console.log("LpRouter deployed at:", address(lpRouter));
        console.log("SwapRouter deployed at:", address(swapRouter));

        // Step 4: Create a basic pool
        createBasicPool();
        
        vm.stopBroadcast();
        
        console.log("=== Simple Deployment Complete ===");
        console.log("You can now test basic Uniswap V4 functionality!");
        console.log("PoolManager:", address(manager));
        console.log("AuctionToken (Token0):", address(token0));
        console.log("BaseToken (Token1):", address(token1));
    }

    function deployPoolManager() internal returns (IPoolManager) {
        return IPoolManager(address(new PoolManager(address(0))));
    }

    function deployRouters(IPoolManager _manager) internal returns (PoolModifyLiquidityTest _lpRouter, PoolSwapTest _swapRouter) {
        _lpRouter = new PoolModifyLiquidityTest(_manager);
        _swapRouter = new PoolSwapTest(_manager);
    }

    function deployTokens() internal returns (AuctionToken _token0, AuctionToken _token1) {
        _token0 = new AuctionToken("AuctionToken", "AUCT", 18);
        _token1 = new AuctionToken("BaseToken", "BASE", 18);
        
        // Mint initial supply
        _token0.mint(msg.sender, 10_000_000 ether);
        _token1.mint(msg.sender, 10_000_000 ether);
    }

    function createBasicPool() internal {
        // Sort tokens by address
        if (address(token1) < address(token0)) {
            (token0, token1) = (token1, token0);
        }

        // Create pool key (no hook for now)
        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(address(token0)),
            currency1: Currency.wrap(address(token1)),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(0))
        });

        // Initialize pool
        manager.initialize(poolKey, Constants.SQRT_PRICE_1_1);
        console.log("Basic pool created without hooks");
        
        // Approve tokens
        token0.approve(address(lpRouter), type(uint256).max);
        token1.approve(address(lpRouter), type(uint256).max);
        
        console.log("Tokens approved for trading");
    }
}