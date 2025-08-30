// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";

import {Constants} from "./base/Constants.sol";
import {Config} from "./base/Config.sol";
import {AuctionToken} from "../src/AuctionToken.sol";

/// @notice Creates a pool with liquidity for auction testing
contract CreatePoolAndMintLiquidityScript is Script, Constants, Config {
    using CurrencyLibrary for Currency;
    using PoolIdLibrary for PoolKey;

    function setUp() public {}

    function run() public returns (PoolKey memory key, PoolId id) {
        console.log("Creating pool and minting liquidity...");
        console.log("Hook contract:", address(hookContract));
        console.log("Auction token:", address(auctionToken));
        console.log("Base token:", address(baseToken));

        // Create pool key
        key = PoolKey({
            currency0: address(auctionToken) < address(baseToken) ? auctionCurrency : baseCurrency,
            currency1: address(auctionToken) < address(baseToken) ? baseCurrency : auctionCurrency,
            fee: 3000, // 0.3%
            tickSpacing: 60,
            hooks: hookContract
        });

        id = key.toId();

        vm.startBroadcast();

        // Initialize the pool
        POOLMANAGER.initialize(key, SQRT_PRICE_1_1);

        // Mint tokens for liquidity provision
        AuctionToken(Currency.unwrap(key.currency0)).mint(msg.sender, 100_000 ether);
        AuctionToken(Currency.unwrap(key.currency1)).mint(msg.sender, 100_000 ether);

        // Note: In a real script, you'd add liquidity via PositionManager
        // For now, just log the pool creation

        vm.stopBroadcast();

        console.log("Pool created with ID:", vm.toString(PoolId.unwrap(id)));
        console.log("Currency0:", Currency.unwrap(key.currency0));
        console.log("Currency1:", Currency.unwrap(key.currency1));
        console.log("Fee:", key.fee);
        console.log("TickSpacing:", key.tickSpacing);

        return (key, id);
    }
}
