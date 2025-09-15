// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";

import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolManager} from "@uniswap/v4-core/src/PoolManager.sol";
import {PoolId} from "@uniswap/v4-core/src/types/PoolId.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";
import {PoolModifyLiquidityTest} from "@uniswap/v4-core/src/test/PoolModifyLiquidityTest.sol";
import {PoolSwapTest} from "@uniswap/v4-core/src/test/PoolSwapTest.sol";
import {SwapRouterNoChecks} from "@uniswap/v4-core/src/test/SwapRouterNoChecks.sol";
import {PoolDonateTest} from "@uniswap/v4-core/src/test/PoolDonateTest.sol";
import {PoolTakeTest} from "@uniswap/v4-core/src/test/PoolTakeTest.sol";
import {PoolClaimsTest} from "@uniswap/v4-core/src/test/PoolClaimsTest.sol";
import {ActionsRouter} from "@uniswap/v4-core/src/test/ActionsRouter.sol";
import {ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";

import {StealthAuctionToken} from "../../src/StealthAuctionToken.sol";

/// @title Deployers
/// @notice Shared utilities for deploying v4 pool infrastructure (Phase 2 - AuctionToken methods disabled)
contract Deployers is Test {
    using CurrencyLibrary for Currency;

    /// @notice Creates a PoolManager and various helper contracts
    function createFreshManager() internal returns (IPoolManager manager) {
        manager = IPoolManager(address(new PoolManager(address(0)))); // No controller
    }

    /// @notice Creates a pool manager, test routers, and test tokens
    function deployFreshManagerAndRouters()
        internal
        returns (
            IPoolManager manager,
            PoolModifyLiquidityTest modifyLiquidityRouter,
            PoolSwapTest swapRouter,
            PoolDonateTest donateRouter,
            PoolTakeTest takeRouter,
            PoolClaimsTest claimsRouter,
            ActionsRouter actionsRouter
        )
    {
        manager = createFreshManager();
        modifyLiquidityRouter = new PoolModifyLiquidityTest(manager);
        swapRouter = new PoolSwapTest(manager);
        donateRouter = new PoolDonateTest(manager);
        takeRouter = new PoolTakeTest(manager);
        claimsRouter = new PoolClaimsTest(manager);
        actionsRouter = new ActionsRouter(manager);
    }

    // TOKEN DEPLOYMENT METHODS DISABLED DURING PHASE 2 MIGRATION
    // Will be updated to use StealthAuctionToken in Phase 3
}
