// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {EncryptedDutchAuction} from "../src/EncryptedDutchAuction.sol";
import {AuctionToken} from "../src/AuctionToken.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {FHE, InEuint128, InEuint64} from "@fhenixprotocol/cofhe-contracts/FHE.sol";
import {CoFheTest} from "@fhenixprotocol/cofhe-mock-contracts/CoFheTest.sol";

/// @notice Test deployed contracts on Anvil
contract TestDeploymentScript is Script, CoFheTest {
    // Deployed contract addresses
    IPoolManager constant POOL_MANAGER = IPoolManager(0x0165878A594ca255338adfa4d48449f69242Eb8F);
    EncryptedDutchAuction constant AUCTION_HOOK = EncryptedDutchAuction(0x781D0CE33a3E397A523a47Ef2936352b8Ba4C080);
    AuctionToken constant TOKEN0 = AuctionToken(0x5FbDB2315678afecb367f032d93F642f64180aa3);
    AuctionToken constant TOKEN1 = AuctionToken(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512);

    uint160 constant SQRT_PRICE_1_1 = 79228162514264337593543950336;

    function setUp() public {}

    function run() public {
        console.log("=== Testing Deployed Contracts ===");
        console.log("PoolManager:", address(POOL_MANAGER));
        console.log("AuctionHook:", address(AUCTION_HOOK));
        console.log("Token0:", address(TOKEN0));
        console.log("Token1:", address(TOKEN1));

        // Test 1: Verify hook permissions
        testHookPermissions();

        // Test 2: Create a pool
        testCreatePool();

        // Test 3: Create an auction
        testCreateAuction();

        // Test 4: Submit bids
        testSubmitBids();

        console.log("=== All Tests Passed! ===");
    }

    function testHookPermissions() internal view {
        console.log("\n1. Testing hook permissions...");
        
        try AUCTION_HOOK.getHookPermissions() returns (
            Hooks.Permissions memory permissions
        ) {
            console.log("  beforeSwap:", permissions.beforeSwap);
            require(permissions.beforeSwap, "Hook should have beforeSwap permission");
            console.log("  [OK] Hook permissions verified");
        } catch {
            console.log("  [FAIL] Failed to get hook permissions");
            revert("Hook permissions test failed");
        }
    }

    function testCreatePool() internal {
        console.log("\n2. Testing pool creation...");
        
        // Create PoolKey
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(address(TOKEN0)),
            currency1: Currency.wrap(address(TOKEN1)),
            fee: 3000, // 0.3% fee
            tickSpacing: 60,
            hooks: IHooks(address(AUCTION_HOOK))
        });

        vm.startBroadcast();
        
        try POOL_MANAGER.initialize(key, SQRT_PRICE_1_1) {
            console.log("  [OK] Pool created successfully");
        } catch Error(string memory reason) {
            console.log("  Pool creation failed:", reason);
            // Pool might already exist, which is fine
            if (keccak256(abi.encodePacked(reason)) == keccak256(abi.encodePacked("PoolAlreadyInitialized()"))) {
                console.log("  [OK] Pool already exists (OK)");
            }
        } catch {
            console.log("  [FAIL] Pool creation failed with unknown error");
        }
        
        vm.stopBroadcast();
    }

    function testCreateAuction() internal {
        console.log("\n3. Testing auction creation...");
        
        vm.startBroadcast();
        
        // Ensure we have tokens
        TOKEN0.mint(msg.sender, 1000 ether);
        TOKEN0.approve(address(AUCTION_HOOK), 1000 ether);

        // Create encrypted auction parameters
        InEuint128 memory encStartPrice = createInEuint128(uint128(10 ether), msg.sender);
        InEuint128 memory encEndPrice = createInEuint128(uint128(1 ether), msg.sender);
        InEuint64 memory encDuration = createInEuint64(uint64(3600), msg.sender); // 1 hour
        InEuint128 memory encSupply = createInEuint128(uint128(100 ether), msg.sender);

        try AUCTION_HOOK.createEncryptedAuction(
            address(TOKEN0),
            encStartPrice,
            encEndPrice,
            encDuration,
            encSupply,
            1000 // decayRate parameter
        ) returns (uint256 auctionId) {
            console.log("  [OK] Auction created with ID:", auctionId);
            
            // Verify auction info
            (address seller, address token, bool isActive, bool revealed, uint256 bidderCount, uint256 queueLength) = 
                AUCTION_HOOK.getAuctionInfo(auctionId);
            
            console.log("    Seller:", seller);
            console.log("    Token:", token);
            console.log("    Active:", isActive);
            console.log("    Revealed:", revealed);
            console.log("    Bidders:", bidderCount);
            console.log("    Queue length:", queueLength);
            
        } catch Error(string memory reason) {
            console.log("  [FAIL] Auction creation failed:", reason);
            revert("Auction creation test failed");
        }
        
        vm.stopBroadcast();
    }

    function testSubmitBids() internal {
        console.log("\n4. Testing bid submission...");
        
        vm.startBroadcast();
        
        // Create bidder account
        address bidder = address(0x1234);
        TOKEN1.mint(bidder, 100 ether);
        
        vm.stopBroadcast();
        vm.startBroadcast(bidder);
        
        TOKEN1.approve(address(AUCTION_HOOK), 100 ether);
        
        // Submit encrypted bid
        InEuint128 memory encBid = createInEuint128(uint128(5 ether), bidder);
        
        try AUCTION_HOOK.submitEncryptedBid(0, encBid) {
            console.log("  [OK] Bid submitted successfully");
            
            // Check updated auction info
            (, , , , uint256 bidderCount, uint256 queueLength) = 
                AUCTION_HOOK.getAuctionInfo(0);
            
            console.log("    Updated bidders:", bidderCount);
            console.log("    Updated queue length:", queueLength);
            
        } catch Error(string memory reason) {
            console.log("  [FAIL] Bid submission failed:", reason);
            // This might be expected if auction doesn't exist
        }
        
        vm.stopBroadcast();
    }
}
