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

// FHE Imports
import {InEuint128, InEuint64, FHE, euint128, euint64, ebool} from "@fhenixprotocol/cofhe-contracts/FHE.sol";
import {CoFheTest} from "@fhenixprotocol/cofhe-mock-contracts/CoFheTest.sol";

/// @title StealthAuction Demo Script
/// @notice Demonstrates comprehensive auction workflow with encrypted parameters
contract StealthAuctionDemo is Script, CoFheTest {
    using PoolIdLibrary for PoolKey;

    // Demo participants
    address public seller;
    address public bidder1;
    address public bidder2;
    address public bidder3;

    // Demo configuration
    struct DemoConfig {
        uint256 auctionSupply;
        uint256 startPrice;
        uint256 endPrice;
        uint256 duration;
        uint256 decayRate;
        uint256[] bidAmounts;
    }

    // Deployment addresses (from environment or previous deployment)
    address public stealthAuctionHook;
    address public auctionToken;
    address public poolManager;
    PoolId public poolId;

    event DemoStarted(string phase);
    event DemoComplete(string summary);
    event AuctionCreated(uint256 indexed auctionId, address indexed seller);
    event BidSubmitted(uint256 indexed auctionId, address indexed bidder, string description);
    event AuctionSettled(uint256 indexed auctionId, string outcome);

    function run() external {
        // Scripts need explicit cheatcode access for CoFheTest mock verifier contracts.
        vm.allowCheatcodes(ZK_VERIFIER_SIGNER_ADDRESS);
        vm.allowCheatcodes(ZK_VERIFIER_ADDRESS);

        _loadConfiguration();
        _setupParticipants();

        console.log("=== StealthAuction FHE Demo Starting ===");
        emit DemoStarted("FHE Dutch Auction Demonstration");

        // Demo phases
        _demoPhase1_AuctionCreation();
        _demoPhase2_BiddingProcess();
        _demoPhase3_PriceDecayDemo();
        _demoPhase4_AuctionSettlement();
        _demoPhase5_ParameterReveal();

        console.log("=== Demo Complete ===");
        emit DemoComplete("All FHE Dutch auction features demonstrated successfully");
    }

    function _loadConfiguration() internal {
        // Load deployment addresses from environment
        stealthAuctionHook = vm.envAddress("STEALTH_AUCTION_HOOK");
        auctionToken = vm.envAddress("AUCTION_TOKEN");
        poolManager = vm.envAddress("POOL_MANAGER");

        // Load pool configuration
        address token0 = vm.envAddress("TOKEN0");
        address token1 = vm.envAddress("TOKEN1");

        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(stealthAuctionHook)
        });
        poolId = key.toId();

        console.log("Loaded deployment configuration:");
        console.log("Hook:", stealthAuctionHook);
        console.log("Auction Token:", auctionToken);
        console.log("Pool Manager:", poolManager);
    }

    function _setupParticipants() internal {
        // Use the auction token owner as seller so owner-only token calls succeed in mock flow.
        seller = StealthAuctionToken(auctionToken).owner();
        bidder1 = vm.addr(2);
        bidder2 = vm.addr(3);
        bidder3 = vm.addr(4);

        console.log("Demo participants:");
        console.log("Seller:", seller);
        console.log("Bidder1:", bidder1);
        console.log("Bidder2:", bidder2);
        console.log("Bidder3:", bidder3);

        // Fund participants
        vm.deal(seller, 100 ether);
        vm.deal(bidder1, 100 ether);
        vm.deal(bidder2, 100 ether);
        vm.deal(bidder3, 100 ether);

        // Distribute auction tokens to seller
        vm.startPrank(seller);
        StealthAuctionToken(auctionToken).mint(seller, 10000 ether);
        vm.stopPrank();

        // Approve hook to spend seller's tokens
        vm.startPrank(seller);
        StealthAuctionToken(auctionToken).approve(stealthAuctionHook, type(uint256).max);
        vm.stopPrank();
    }

    function _demoPhase1_AuctionCreation() internal {
        console.log("\n=== PHASE 1: Creating FHE Dutch Auction ===");
        emit DemoStarted("Creating encrypted Dutch auction");

        DemoConfig memory config = DemoConfig({
            auctionSupply: 1000 ether,
            startPrice: 10 ether,
            endPrice: 1 ether,
            duration: 3600, // 1 hour
            decayRate: 100,
            bidAmounts: new uint256[](3)
        });
        config.bidAmounts[0] = 8 ether;
        config.bidAmounts[1] = 6 ether;
        config.bidAmounts[2] = 9 ether;

        vm.startPrank(seller);

        // Initialize auction token supply (as token owner)
        InEuint128 memory encSupplyForToken = _createEncryptedInput(uint128(config.auctionSupply), seller);
        StealthAuctionToken(auctionToken).initializeAuctionSupply(stealthAuctionHook, encSupplyForToken);

        vm.stopPrank();

        vm.startPrank(seller);

        // Seller creates encrypted auction parameters
        InEuint128 memory encStartPrice = _createEncryptedInput(uint128(config.startPrice), seller);
        InEuint128 memory encEndPrice = _createEncryptedInput(uint128(config.endPrice), seller);
        InEuint64 memory encDuration = _createEncryptedInput64(uint64(config.duration), seller);
        InEuint128 memory encSupplyForAuction = _createEncryptedInput(uint128(config.auctionSupply), seller);

        uint256 auctionId = StealthAuction(stealthAuctionHook)
            .createEncryptedAuction(
                poolId, auctionToken, encStartPrice, encEndPrice, encDuration, encSupplyForAuction, config.decayRate
            );

        vm.stopPrank();

        console.log("Auction created with ID:", auctionId);
        console.log("Encrypted parameters stored on-chain");
        console.log("Start Price: [ENCRYPTED] ~", config.startPrice / 1e18, "ETH");
        console.log("End Price: [ENCRYPTED] ~", config.endPrice / 1e18, "ETH");
        console.log("Duration: [ENCRYPTED] ~", config.duration / 3600, "hours");
        console.log("Supply: [ENCRYPTED] ~", config.auctionSupply / 1e18, "tokens");

        emit AuctionCreated(auctionId, seller);
    }

    function _demoPhase2_BiddingProcess() internal {
        console.log("\n=== PHASE 2: Encrypted Bidding Process ===");
        emit DemoStarted("Demonstrating encrypted bid submissions");

        uint256 auctionId = 1; // From phase 1

        // Bidder 1: Submit encrypted bid
        vm.startPrank(bidder1);
        InEuint128 memory bid1 = _createEncryptedInput(uint128(8 ether), bidder1);
        StealthAuction(stealthAuctionHook).submitEncryptedBid(auctionId, bid1);
        vm.stopPrank();

        console.log("Bidder1 submitted encrypted bid: [ENCRYPTED] ~8 ETH");
        emit BidSubmitted(auctionId, bidder1, "High value encrypted bid");

        // Bidder 2: Submit encrypted bid
        vm.startPrank(bidder2);
        InEuint128 memory bid2 = _createEncryptedInput(uint128(6 ether), bidder2);
        StealthAuction(stealthAuctionHook).submitEncryptedBid(auctionId, bid2);
        vm.stopPrank();

        console.log("Bidder2 submitted encrypted bid: [ENCRYPTED] ~6 ETH");
        emit BidSubmitted(auctionId, bidder2, "Medium value encrypted bid");

        // Bidder 3: Submit encrypted bid
        vm.startPrank(bidder3);
        InEuint128 memory bid3 = _createEncryptedInput(uint128(9 ether), bidder3);
        StealthAuction(stealthAuctionHook).submitEncryptedBid(auctionId, bid3);
        vm.stopPrank();

        console.log("Bidder3 submitted encrypted bid: [ENCRYPTED] ~9 ETH");
        emit BidSubmitted(auctionId, bidder3, "Highest value encrypted bid");

        // Show auction state
        (
            address auctionSeller,
            address tokenAddr,
            bool isActive,
            bool revealed,
            uint256 bidderCount,
            uint256 queueLength
        ) = StealthAuction(stealthAuctionHook).getAuctionInfo(auctionId);

        console.log("Auction State:");
        console.log("- Active:", isActive);
        console.log("- Bidder Count:", bidderCount);
        console.log("- Queue Length:", queueLength);
        console.log("- Parameters Revealed:", revealed);
    }

    function _demoPhase3_PriceDecayDemo() internal {
        console.log("\n=== PHASE 3: Price Decay Demonstration ===");
        emit DemoStarted("Demonstrating encrypted price decay over time");

        uint256 auctionId = 1;

        console.log("Current blockchain time:", block.timestamp);

        // Demonstrate price checks at different times
        uint256 currentPrice = StealthAuction(stealthAuctionHook).getCurrentPrice(auctionId);
        console.log("Current auction price: [ENCRYPTED/PLACEHOLDER]", currentPrice);

        // Advance time to middle of auction
        vm.warp(block.timestamp + 1800); // 30 minutes
        console.log("Advanced time by 30 minutes");

        uint256 midPrice = StealthAuction(stealthAuctionHook).getCurrentPrice(auctionId);
        console.log("Mid-auction price: [ENCRYPTED/PLACEHOLDER]", midPrice);

        // Check auction status
        bool isActive = StealthAuction(stealthAuctionHook).isAuctionActive(auctionId);
        console.log("Auction still active:", isActive);

        console.log("Note: Price decay is computed using FHE operations");
        console.log("Actual price values remain encrypted until settlement");
    }

    function _demoPhase4_AuctionSettlement() internal {
        console.log("\n=== PHASE 4: Auction Settlement ===");
        emit DemoStarted("Settling auction with encrypted computations");

        uint256 auctionId = 1;

        // Advance to auction end
        vm.warp(block.timestamp + 1800); // Another 30 minutes (total 1 hour)
        console.log("Auction duration completed");

        vm.startPrank(seller);

        // Settle the auction
        StealthAuction(stealthAuctionHook).settleAuction(auctionId);

        vm.stopPrank();

        console.log("Auction settled successfully");
        console.log("Settlement process:");
        console.log("1. Encrypted bids compared to final encrypted price");
        console.log("2. Winning bids determined using FHE operations");
        console.log("3. Token distributions calculated privately");
        console.log("4. Settlement completed without revealing bid values");

        emit AuctionSettled(auctionId, "Settlement completed with encrypted computations");
    }

    function _demoPhase5_ParameterReveal() internal {
        console.log("\n=== PHASE 5: Parameter Revelation ===");
        emit DemoStarted("Revealing auction parameters post-settlement");

        uint256 auctionId = 1;

        vm.startPrank(seller);

        // Reveal parameters (seller's choice)
        StealthAuction(stealthAuctionHook).revealParameters(auctionId);

        vm.stopPrank();

        console.log("Auction parameters revealed by seller");
        console.log("This allows participants to verify the auction was fair");
        console.log("Revelation is optional and controlled by the seller");

        // Final auction state
        (
            address auctionSeller,
            address tokenAddr,
            bool isActive,
            bool revealed,
            uint256 bidderCount,
            uint256 queueLength
        ) = StealthAuction(stealthAuctionHook).getAuctionInfo(auctionId);

        console.log("\nFinal Auction State:");
        console.log("- Seller:", auctionSeller);
        console.log("- Token:", tokenAddr);
        console.log("- Active:", isActive);
        console.log("- Parameters Revealed:", revealed);
        console.log("- Total Bidders:", bidderCount);
        console.log("- Final Queue Length:", queueLength);
    }

    // Helper function to create encrypted inputs
    function _createEncryptedInput(uint128 value, address signer) internal returns (InEuint128 memory) {
        // Use CoFheTest helper function for proper encrypted input creation
        return createInEuint128(value, signer);
    }

    function _createEncryptedInput64(uint64 value, address signer) internal returns (InEuint64 memory) {
        // Use CoFheTest helper function for proper encrypted input creation
        return createInEuint64(value, signer);
    }

    // Utility functions for demo
    function _formatEther(uint256 amount) internal pure returns (string memory) {
        return string(abi.encodePacked(vm.toString(amount / 1e18), " ETH"));
    }

    function _formatTokens(uint256 amount) internal pure returns (string memory) {
        return string(abi.encodePacked(vm.toString(amount / 1e18), " tokens"));
    }
}
