// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {Constants} from "./base/Constants.sol";
import {Config} from "./base/Config.sol";
import {StealthAuction} from "../src/StealthAuction.sol";
import {InEuint128, InEuint64} from "@fhenixprotocol/cofhe-contracts/FHE.sol";
import {PoolId} from "@uniswap/v4-core/src/types/PoolId.sol";

// FHE Imports
import {CoFheTest} from "@fhenixprotocol/cofhe-mock-contracts/CoFheTest.sol";

/// @notice Demonstrates creating and interacting with stealth auctions
contract AuctionDemoScript is Script, Constants, Config, CoFheTest {
    StealthAuction auction;

    function setUp() public {
        auction = StealthAuction(address(HOOK_CONTRACT));
    }

    function run() public {
        console.log("=== StealthAuction Demo ===");
        console.log("Hook address:", address(auction));
        console.log("Auction token:", address(AUCTION_TOKEN));
        console.log("Seller:", msg.sender);

        // Demo: Create an encrypted auction
        uint256 auctionId = createDemoAuction();
        
        // Demo: Submit encrypted bids
        submitDemoBids(auctionId);
        
        // Demo: Check auction info
        checkAuctionInfo(auctionId);
        
        console.log("=== Demo Complete ===");
    }

    function createDemoAuction() public returns (uint256 auctionId) {
        console.log("\n--- Creating Encrypted Auction ---");

        vm.startBroadcast();

        // Mint tokens for auction
        AUCTION_TOKEN.mint(msg.sender, DEFAULT_SUPPLY);
        AUCTION_TOKEN.approve(address(auction), DEFAULT_SUPPLY);

        // Create encrypted inputs using CoFHE test helpers
        // For demo, using mock encryption
        InEuint128 memory encStartPrice = createInEuint128(uint128(DEFAULT_START_PRICE), msg.sender);
        InEuint128 memory encEndPrice = createInEuint128(uint128(DEFAULT_END_PRICE), msg.sender);
        InEuint64 memory encDuration = createInEuint64(uint64(DEFAULT_DURATION), msg.sender);
        InEuint128 memory encSupply = createInEuint128(uint128(DEFAULT_SUPPLY), msg.sender);

        // Create auction
        auctionId = auction.createEncryptedAuction(
            PoolId.wrap(0), // Using zero pool ID as placeholder
            address(AUCTION_TOKEN),
            encStartPrice,
            encEndPrice,
            encDuration,
            encSupply,
            DEFAULT_DECAY_RATE
        );

        vm.stopBroadcast();

        console.log("Auction created with ID:", auctionId);
        console.log("Encrypted parameters set (start/end price, duration hidden)");
        
        return auctionId;
    }

    function submitDemoBids(uint256 auctionId) public {
        console.log("\n--- Submitting Encrypted Bids ---");
        
        // Create demo bidders
        address bidder1 = address(0x1111);
        address bidder2 = address(0x2222);
        address bidder3 = address(0x3333);

        // Bid 1: High bid (8 ETH)
        vm.startBroadcast(bidder1);
        InEuint128 memory bid1 = createInEuint128(uint128(8 ether), bidder1);
        auction.submitEncryptedBid(auctionId, bid1);
        vm.stopBroadcast();
        console.log("Bidder1 submitted encrypted bid");

        // Bid 2: Medium bid (5 ETH) 
        vm.startBroadcast(bidder2);
        InEuint128 memory bid2 = createInEuint128(uint128(5 ether), bidder2);
        auction.submitEncryptedBid(auctionId, bid2);
        vm.stopBroadcast();
        console.log("Bidder2 submitted encrypted bid");

        // Bid 3: Low bid (2 ETH)
        vm.startBroadcast(bidder3);
        InEuint128 memory bid3 = createInEuint128(uint128(2 ether), bidder3);
        auction.submitEncryptedBid(auctionId, bid3);
        vm.stopBroadcast();
        console.log("Bidder3 submitted encrypted bid");

        console.log("All bids encrypted - outcomes hidden until settlement");
    }

    function checkAuctionInfo(uint256 auctionId) public view {
        console.log("\n--- Auction Information ---");
        
        (
            address seller,
            address token,
            bool isActive,
            bool revealed,
            uint256 bidderCount,
            uint256 queueLength
        ) = auction.getAuctionInfo(auctionId);

        console.log("Seller:", seller);
        console.log("Token:", token);
        console.log("Active:", isActive);
        console.log("Parameters revealed:", revealed);
        console.log("Bidder count:", bidderCount);
        console.log("Queue length:", queueLength);

        // Current price (returns placeholder in current implementation)
        uint256 currentPrice = auction.getCurrentPrice(auctionId);
        console.log("Current price:", currentPrice, "(placeholder - actual price encrypted)");
    }

    /// @notice Demo settlement (would be called after auction period)
    function settleDemoAuction(uint256 auctionId) public {
        console.log("\n--- Settling Auction ---");
        
        vm.startBroadcast();
        auction.settleAuction(auctionId);
        vm.stopBroadcast();
        
        console.log("Auction settled - tokens distributed to winning bidders");
    }

    /// @notice Demo parameter reveal (optional)
    function revealDemoParameters(uint256 auctionId) public {
        console.log("\n--- Revealing Parameters ---");
        
        vm.startBroadcast();
        auction.revealParameters(auctionId);
        vm.stopBroadcast();
        
        console.log("Auction parameters revealed (if desired by seller)");
    }
}
