// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {StealthAuction} from "../src/StealthAuction.sol";
import {StealthAuctionToken} from "../src/StealthAuctionToken.sol";

/// @title Interactive StealthAuction Demo
/// @notice Step-by-step interactive demonstration of FHE Dutch auction features
contract InteractiveDemo is Script {
    StealthAuction public hook;
    StealthAuctionToken public auctionToken;

    address public seller = vm.addr(1);
    address public bidder1 = vm.addr(2);
    address public bidder2 = vm.addr(3);

    event DemoStep(uint256 step, string description);

    function run() external {
        console.log("=== Interactive StealthAuction Demo ===\n");

        // Load deployed contracts
        _loadContracts();

        // Interactive demo steps
        _step1_Overview();
        _step2_AuctionCreation();
        _step3_BiddingDemo();
        _step4_EncryptionBenefits();
        _step5_SettlementDemo();
        _step6_TechnicalDetails();

        console.log("=== Demo Complete ===");
        console.log("The StealthAuction system demonstrates how FHE enables");
        console.log("private, fair, and efficient Dutch auctions on Ethereum.");
    }

    function _loadContracts() internal {
        address hookAddr = vm.envAddress("STEALTH_AUCTION_HOOK");
        address tokenAddr = vm.envAddress("AUCTION_TOKEN");

        hook = StealthAuction(hookAddr);
        auctionToken = StealthAuctionToken(tokenAddr);

        console.log("Loaded contracts:");
        console.log("Hook:", address(hook));
        console.log("Token:", address(auctionToken));
    }

    function _step1_Overview() internal {
        emit DemoStep(1, "System Overview");

        console.log("STEP 1: StealthAuction Overview");
        console.log("-------------------------------");
        console.log("");
        console.log("StealthAuction is a FHE-powered Dutch auction system that enables:");
        console.log("* Private auction parameters (start/end price, duration)");
        console.log("* Confidential bidding (bid amounts hidden)");
        console.log("* Fair price discovery with encrypted computations");
        console.log("* MEV-resistant auction mechanics");
        console.log("* Integration with Uniswap v4 for liquidity");
        console.log("");
        console.log("Key Innovation: All sensitive data remains encrypted on-chain,");
        console.log("while still enabling complex auction logic and fair settlements.");
        console.log("");

        _pause();
    }

    function _step2_AuctionCreation() internal {
        emit DemoStep(2, "Auction Creation");

        console.log("STEP 2: Creating an Encrypted Dutch Auction");
        console.log("------------------------------------------");
        console.log("");
        console.log("The seller creates an auction with encrypted parameters:");
        console.log("");
        console.log("Traditional Dutch Auction:");
        console.log("X Start Price: 10 ETH (public)");
        console.log("X End Price: 1 ETH (public)");
        console.log("X Duration: 1 hour (public)");
        console.log("X Supply: 1000 tokens (public)");
        console.log("");
        console.log("StealthAuction (FHE-powered):");
        console.log("+ Start Price: [ENCRYPTED]");
        console.log("+ End Price: [ENCRYPTED]");
        console.log("+ Duration: [ENCRYPTED]");
        console.log("+ Supply: [ENCRYPTED]");
        console.log("");
        console.log("Benefits:");
        console.log("* No front-running based on auction parameters");
        console.log("* Sellers can't be gamed by sophisticated bidders");
        console.log("* True price discovery without information asymmetry");
        console.log("");

        _pause();
    }

    function _step3_BiddingDemo() internal {
        emit DemoStep(3, "Bidding Process");

        console.log("STEP 3: Encrypted Bidding Process");
        console.log("---------------------------------");
        console.log("");
        console.log("Bidders submit encrypted bids without revealing amounts:");
        console.log("");
        console.log("Traditional Auction:");
        console.log("X Bidder A: 8 ETH (visible to all)");
        console.log("X Bidder B: 6 ETH (visible to all)");
        console.log("X Bidder C: 9 ETH (visible to all)");
        console.log("X Result: Information leakage, potential manipulation");
        console.log("");
        console.log("StealthAuction:");
        console.log("+ Bidder A: [ENCRYPTED BID]");
        console.log("+ Bidder B: [ENCRYPTED BID]");
        console.log("+ Bidder C: [ENCRYPTED BID]");
        console.log("+ Result: Private competitive bidding");
        console.log("");
        console.log("Key Features:");
        console.log("* Bid amounts encrypted with bidder's private key");
        console.log("* Duplicate bid prevention without revealing amounts");
        console.log("* Real-time bid validation against encrypted current price");
        console.log("* Queue management preserves bid order privately");
        console.log("");

        _pause();
    }

    function _step4_EncryptionBenefits() internal {
        emit DemoStep(4, "FHE Benefits Analysis");

        console.log("STEP 4: Why Fully Homomorphic Encryption (FHE)?");
        console.log("----------------------------------------------");
        console.log("");
        console.log("Problem with Traditional Approaches:");
        console.log("X Commit-Reveal: Vulnerable to reveal-phase manipulation");
        console.log("X Zero-Knowledge: Limited computational capabilities");
        console.log("X Trusted Hardware: Centralization and availability issues");
        console.log("X Multi-Party Computation: Complex coordination overhead");
        console.log("");
        console.log("FHE Solution:");
        console.log("+ Compute on encrypted data directly");
        console.log("+ No trusted setup or reveal phases");
        console.log("+ Fully decentralized execution");
        console.log("+ Rich computational operations (comparison, arithmetic)");
        console.log("");
        console.log("StealthAuction FHE Operations:");
        console.log("* Price decay: encrypt_price = start_price - (time_elapsed * decay_rate)");
        console.log("* Bid validation: valid = encrypt_bid >= encrypt_current_price");
        console.log("* Settlement: winners = filter(bids, >= final_price)");
        console.log("* Token allocation: amounts = calculate_distribution(winners, supply)");
        console.log("");
        console.log("All operations maintain privacy while enabling complex logic!");
        console.log("");

        _pause();
    }

    function _step5_SettlementDemo() internal {
        emit DemoStep(5, "Settlement Process");

        console.log("STEP 5: Private Settlement and Token Distribution");
        console.log("------------------------------------------------");
        console.log("");
        console.log("Settlement Process:");
        console.log("1. Calculate final encrypted price at auction end");
        console.log("2. Compare all encrypted bids to final price");
        console.log("3. Determine winning bids using FHE operations");
        console.log("4. Calculate token distributions privately");
        console.log("5. Execute transfers without revealing amounts");
        console.log("");
        console.log("Privacy Guarantees:");
        console.log("+ Losing bid amounts never revealed");
        console.log("+ Final price remains hidden (unless seller chooses to reveal)");
        console.log("+ Individual allocations computed privately");
        console.log("+ Only aggregate statistics may be public");
        console.log("");
        console.log("Fairness Guarantees:");
        console.log("+ No preferential treatment based on bid timing");
        console.log("+ Uniform price for all winning bidders");
        console.log("+ Transparent settlement algorithm");
        console.log("+ Verifiable fairness without compromising privacy");
        console.log("");

        _pause();
    }

    function _step6_TechnicalDetails() internal {
        emit DemoStep(6, "Technical Implementation");

        console.log("STEP 6: Technical Implementation Details");
        console.log("--------------------------------------");
        console.log("");
        console.log("Architecture Components:");
        console.log("* StealthAuction Hook: Core auction logic + Uniswap v4 integration");
        console.log("* StealthAuctionToken: FHE-enabled ERC20 with encrypted balances");
        console.log("* BidQueue: Encrypted bid ordering and management");
        console.log("* FHEPermissions: Cryptographic access control system");
        console.log("* AuctionLibrary: Shared auction utilities and calculations");
        console.log("");
        console.log("Uniswap v4 Integration (4 hooks enabled):");
        console.log("* beforeSwap: Auction-aware swap processing");
        console.log("* afterSwap: Post-swap auction state updates");
        console.log("* afterInitialize: Pool initialization handling");
        console.log("* beforeAddLiquidity: Liquidity validation");
        console.log("");
        console.log("Security Model:");
        console.log("* FHE operations use threshold encryption");
        console.log("* Private keys managed through secure key derivation");
        console.log("* Access control via signature verification");
        console.log("* Reentrancy protection on all state changes");
        console.log("");
        console.log("Gas Optimization:");
        console.log("* Batch FHE operations where possible");
        console.log("* Efficient encrypted storage patterns");
        console.log("* Optimized hook flag calculations");
        console.log("* Minimal on-chain computation overhead");
        console.log("");

        _pause();
    }

    function _pause() internal view {
        console.log("Press Enter to continue...");
        // In a real interactive demo, this would wait for user input
        // For automated demo, we just add spacing
        console.log("");
    }

    // Utility function to demonstrate current auction state
    function showAuctionState(uint256 auctionId) external view {
        (address auctionSeller, address token, bool isActive, bool revealed, uint256 bidderCount, uint256 queueLength) =
            hook.getAuctionInfo(auctionId);

        console.log("Current Auction State:");
        console.log("---------------------");
        console.log("Auction ID:", auctionId);
        console.log("Seller:", auctionSeller);
        console.log("Token:", token);
        console.log("Active:", isActive);
        console.log("Parameters Revealed:", revealed);
        console.log("Bidder Count:", bidderCount);
        console.log("Queue Length:", queueLength);
        console.log("");
    }
}
