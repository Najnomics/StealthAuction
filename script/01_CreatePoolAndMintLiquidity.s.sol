// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";

import {Constants} from "./base/Constants.sol";
import {Config} from "./base/Config.sol";
// DEPRECATED IMPORT - AuctionToken replaced by StealthAuctionToken
// import {AuctionToken} from "../src/AuctionToken.sol";
import {StealthAuctionToken} from "../src/StealthAuctionToken.sol";

/// @notice Creates a pool with liquidity for auction testing
contract CreatePoolAndMintLiquidityScript is Script, Constants, Config {
    using CurrencyLibrary for Currency;
    using PoolIdLibrary for PoolKey;

    function setUp() public {}

    function run() public returns (PoolKey memory key, PoolId id) {
        console.log("Creating pool and minting liquidity...");
        console.log("Hook contract:", address(HOOK_CONTRACT));
        console.log("Auction token:", address(AUCTION_TOKEN));
        console.log("Base token:", address(BASE_TOKEN));

        // Create pool key
        key = PoolKey({
            currency0: address(AUCTION_TOKEN) < address(BASE_TOKEN) ? AUCTION_CURRENCY : BASE_CURRENCY,
            currency1: address(AUCTION_TOKEN) < address(BASE_TOKEN) ? BASE_CURRENCY : AUCTION_CURRENCY,
            fee: 3000, // 0.3%
            tickSpacing: 60,
            hooks: HOOK_CONTRACT
        });

        id = key.toId();

        vm.startBroadcast();

        // Initialize the pool
        POOLMANAGER.initialize(key, SQRT_PRICE_1_1);

        // Mint tokens for liquidity provision
        // COMMENTED OUT - Need to update for StealthAuctionToken 
        // StealthAuctionToken(Currency.unwrap(key.currency0)).mint(msg.sender, 100_000 ether);
        // StealthAuctionToken(Currency.unwrap(key.currency1)).mint(msg.sender, 100_000 ether);

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
