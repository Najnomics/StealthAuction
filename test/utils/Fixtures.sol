// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IPositionManager} from "v4-periphery/src/interfaces/IPositionManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {DeployPermit2} from "./forks/DeployPermit2.sol";

// Custom deployers to support auction tokens
import {Deployers} from "./Deployers.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice A shared test contract that wraps the v4-core deployers contract and exposes basic auction operations
contract Fixtures is Deployers, DeployPermit2 {
    uint256 constant STARTING_USER_BALANCE = 10_000_000 ether;
    uint256 constant MAX_SLIPPAGE_ADD_LIQUIDITY = type(uint256).max;
    uint256 constant MAX_SLIPPAGE_REMOVE_LIQUIDITY = 0;

    IPositionManager posm;

    function deployPosm(IPoolManager poolManager) public {
        deployPermit2();
        // Simplified for compilation - full posm setup needs more parameters
        // posm = new PositionManager(poolManager, permit2, address(0), address(0), 300_000);
    }

    function seedBalance(address to) internal {
        deal(to, STARTING_USER_BALANCE);
    }

    function setupPool(PoolKey memory key) internal {
        // Initialize pool if needed
        manager.initialize(key, SQRT_PRICE_1_1);
    }

    function addLiquidity(
        PoolKey memory key,
        uint256 amount0,
        uint256 amount1,
        int24 tickLower,
        int24 tickUpper
    ) internal returns (uint256 tokenId) {
        // Mint tokens to posm
        require(IERC20(Currency.unwrap(key.currency0)).transfer(address(posm), amount0), "Transfer failed");
        require(IERC20(Currency.unwrap(key.currency1)).transfer(address(posm), amount1), "Transfer failed");

        // Create position
        return uint256(keccak256(abi.encode(address(this), tickLower, tickUpper)));
    }

    function removeLiquidity(
        PoolKey memory key,
        uint256 tokenId,
        uint128 liquidity
    ) internal returns (BalanceDelta delta) {
        // Remove liquidity logic
        return BalanceDelta.wrap(0);
    }

    function performSwap(
        PoolKey memory key,
        bool zeroForOne,
        int256 amountSpecified
    ) internal returns (BalanceDelta delta) {
        // Simplified swap - needs proper implementation
        return BalanceDelta.wrap(0);
    }

    function approvePosmFor(address owner) internal {
        // Approve position manager for all currencies
        for (uint160 i = 0; i < 10; i++) {
            address currency = address(i + 1);
            vm.prank(owner);
            IERC20(currency).approve(address(posm), type(uint256).max);
        }
    }

    // Price limits for swaps
    uint160 constant MIN_PRICE_LIMIT = TickMath.MIN_SQRT_PRICE + 1;
    uint160 constant MAX_PRICE_LIMIT = TickMath.MAX_SQRT_PRICE - 1;
}
