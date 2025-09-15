// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title StealthAuction
 * @dev A Uniswap V4 hook that enables confidential stealth auctions using Fully Homomorphic Encryption (FHE)
 *
 * This contract allows sellers to create stealth auctions with complete privacy - encrypting starting price,
 * ending price, duration, and current progress. Bidders submit encrypted bids that are validated privately
 * against the hidden current price, preventing front-running, sniping, and coordination attacks.
 *
 * Key Features:
 * - Encrypted auction parameters (start/end price, duration, supply)
 * - Private bid validation using FHE comparison operations
 * - Hidden price decay computed homomorphically
 * - MEV-resistant auction mechanism
 * - Optional parameter reveal post-settlement
 */

// Uniswap v4 Imports
import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {SwapParams, ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";

// Token Imports
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";

// FHE Token Interface
import {IFHERC20} from "./interface/IFHERC20.sol";

// FHE Imports - Using the real CoFHE library
import {FHE, InEuint128, InEuint64, euint128, euint64, ebool} from "@fhenixprotocol/cofhe-contracts/FHE.sol";

// Local Library Imports
import {AuctionLibrary} from "./lib/AuctionLibrary.sol";
import {BidQueue} from "./lib/BidQueue.sol";
import {FHEPermissions} from "./lib/FHEPermissions.sol";

/// @title Stealth Auction Hook
/// @notice Enables confidential stealth auctions on Uniswap v4
contract StealthAuction is BaseHook, ReentrancyGuardTransient {
    using SafeERC20 for IERC20;
    using PoolIdLibrary for PoolKey;

    // =============================================================
    //                           MODIFIERS
    // =============================================================

    modifier onlyByManager() {
        if (msg.sender != address(poolManager)) revert NotManager();
        _;
    }

    error NotManager();

    // =============================================================
    //                           STRUCTS
    // =============================================================

    /// @notice Represents an encrypted Dutch auction
    struct DutchAuctionData {
        PoolId poolId; // Associated pool ID
        euint128 startPrice; // Encrypted starting price
        euint128 endPrice; // Encrypted ending price
        euint64 duration; // Encrypted auction duration
        euint128 totalSupply; // Encrypted total token supply
        euint128 soldAmount; // Encrypted amount sold so far
        euint64 startTime; // Encrypted start timestamp
        ebool isActive; // Encrypted active status
        address seller; // Public seller address
        address token; // Public token address
        bool parametersRevealed; // Public reveal status
        uint256 decayRate; // Public decay rate
        BidQueue bidQueue; // Bid queue for this auction
    }

    /// @notice Represents an encrypted bid
    struct BidData {
        euint128 bidAmount; // Encrypted bid amount
        euint128 allocation; // Encrypted token allocation
        address bidder; // Public bidder address
        uint256 timestamp; // Public timestamp
        bool settled; // Public settlement status
    }

    // =============================================================
    //                           STORAGE
    // =============================================================

    /// @dev Temporary struct to pass encrypted data between helper functions (avoids stack too deep)
    struct TempEncryptionData {
        euint128 startPrice;
        euint128 endPrice;
        euint64 duration;
        euint128 supply;
    }

    mapping(uint256 => DutchAuctionData) public auctions;
    mapping(uint256 => mapping(address => BidData)) public bids;
    mapping(uint256 => address[]) public bidders;

    /// @dev Temporary storage for auction creation (to avoid stack too deep errors)
    mapping(uint256 => TempEncryptionData) private _tempAuctionEncryption;

    // Pool-auction coordination state
    mapping(PoolId => uint256) public poolAuctionCount;
    mapping(PoolId => uint256[]) public poolActiveAuctions;
    mapping(address => uint256[]) public userAuctions;
    mapping(address => uint256[]) public userBids;

    uint256 public nextAuctionId = 1;

    // =============================================================
    //                           EVENTS
    // =============================================================

    event AuctionCreated(uint256 indexed auctionId, address indexed seller, address indexed token, uint256 timestamp);

    event BidSubmitted(uint256 indexed auctionId, address indexed bidder, uint256 timestamp);

    event AuctionSettled(uint256 indexed auctionId, uint256 totalSold, uint256 bidderCount);

    event ParametersRevealed(uint256 indexed auctionId, uint128 startPrice, uint128 endPrice, uint64 duration);

    // Hook-related events
    event PoolInitialized(PoolId indexed poolId, address currency0, address currency1);
    event LiquidityAuctionInteraction(PoolId indexed poolId, uint256 affectedAuctions);
    event PostSwapAuctionUpdate(PoolId indexed poolId, uint256 affectedAuctions);
    event AuctionSwapProcessed(uint256 indexed auctionId, address indexed sender);
    event SwapValidatedAgainstAuctions(PoolId indexed poolId, uint256 auctionCount);
    event BidSettled(uint256 indexed auctionId, address indexed bidder, uint256 timestamp);

    // =============================================================
    //                           ERRORS
    // =============================================================

    error AuctionNotFound();
    error AuctionNotActive();
    error BidAlreadyExists();
    error UnauthorizedSeller();
    error InvalidBid();
    error InsufficientTokenBalance();
    error SwapExceedsAuctionLimit(uint256 auctionId);
    error BidNotFound();
    error PoolNotInitialized(PoolId poolId);

    // =============================================================
    //                        CONSTRUCTOR
    // =============================================================

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {
        // Initialize basic FHE permissions (following Iceberg pattern)
        euint128 zeroAmount = FHE.asEuint128(0);
        FHE.allowThis(zeroAmount);
    }

    // =============================================================
    //                      HOOK PERMISSIONS
    // =============================================================

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: true, // ✅ RE-ENABLED: Following Iceberg pattern
            beforeAddLiquidity: true, // ✅ ENABLED: Per comprehensive fix plan
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true, // ✅ EXISTING: Core auction logic
            afterSwap: true, // ✅ RE-ENABLED: Following Iceberg pattern
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    // =============================================================
    //                    AUCTION CREATION
    // =============================================================

    function createEncryptedAuction(
        PoolId poolId,
        address token,
        InEuint128 calldata startPrice,
        InEuint128 calldata endPrice,
        InEuint64 calldata duration,
        InEuint128 calldata supply,
        uint256 decayRate
    ) external nonReentrant returns (uint256 auctionId) {
        // ✅ Step 1: Import FHE.sol (done at file level)
        // ✅ Step 2: Call Operation & ✅ Step 3: Define Access

        auctionId = nextAuctionId++;

        // Create encrypted values and set permissions in helper function
        _setupAuctionEncryption(auctionId, startPrice, endPrice, duration, supply, token);

        // Create auction data structure in helper function
        _createAuctionData(auctionId, poolId, token, decayRate);

        // Track auction for user and pool
        userAuctions[msg.sender].push(auctionId);
        addAuctionToPool(poolId, auctionId);

        emit AuctionCreated(auctionId, msg.sender, token, block.timestamp);
    }

    /// @dev Helper function to handle FHE encryption and permissions setup
    function _setupAuctionEncryption(
        uint256 auctionId,
        InEuint128 calldata startPrice,
        InEuint128 calldata endPrice,
        InEuint64 calldata duration,
        InEuint128 calldata supply,
        address token
    ) private {
        // Convert to encrypted values
        euint128 encStartPrice = FHE.asEuint128(startPrice);
        euint128 encEndPrice = FHE.asEuint128(endPrice);
        euint64 encDuration = FHE.asEuint64(duration);
        euint128 encSupply = FHE.asEuint128(supply);

        // Grant auction creation permissions
        FHEPermissions.grantAuctionCreationPermissions(
            encStartPrice, encEndPrice, encDuration, encSupply, msg.sender, token, address(this)
        );

        // Store in temporary mapping to pass to next helper
        _tempAuctionEncryption[auctionId] = TempEncryptionData({
            startPrice: encStartPrice,
            endPrice: encEndPrice,
            duration: encDuration,
            supply: encSupply
        });
    }

    /// @dev Helper function to create auction data structure
    function _createAuctionData(uint256 auctionId, PoolId poolId, address token, uint256 decayRate) private {
        TempEncryptionData memory tempData = _tempAuctionEncryption[auctionId];

        // Create time and status encrypted values
        euint64 encStartTime = FHE.asEuint64(block.timestamp);
        ebool encIsActive = FHE.asEbool(true);
        euint128 encZeroAmount = FHE.asEuint128(0);

        // Set time and status permissions
        FHEPermissions.grantTimePermissions(
            encStartTime, tempData.duration, FHE.asEuint64(block.timestamp), msg.sender, address(this)
        );
        FHEPermissions.grantBoolPermissions(encIsActive, msg.sender, address(this));

        // Grant permissions for zero amount (sold tracking)
        FHE.allowThis(encZeroAmount);
        FHE.allow(encZeroAmount, msg.sender);

        // Create bid queue for this auction
        BidQueue bidQueue = new BidQueue();

        // Create auction data
        auctions[auctionId] = DutchAuctionData({
            poolId: poolId,
            startPrice: tempData.startPrice,
            endPrice: tempData.endPrice,
            duration: tempData.duration,
            totalSupply: tempData.supply,
            soldAmount: encZeroAmount,
            startTime: encStartTime,
            isActive: encIsActive,
            seller: msg.sender,
            token: token,
            parametersRevealed: false,
            decayRate: decayRate,
            bidQueue: bidQueue
        });

        // Clean up temporary data
        delete _tempAuctionEncryption[auctionId];
    }

    // =============================================================
    //                        BIDDING
    // =============================================================

    function submitEncryptedBid(uint256 auctionId, InEuint128 calldata bidAmount) external nonReentrant {
        DutchAuctionData storage auction = auctions[auctionId];

        if (auction.seller == address(0)) revert AuctionNotFound();
        if (bids[auctionId][msg.sender].bidder != address(0)) revert BidAlreadyExists();

        // ✅ Step 2: Call Operation
        euint128 encBidAmount = FHE.asEuint128(bidAmount);

        // Calculate current price with proper permissions
        euint128 currentPrice = AuctionLibrary.calculateLinearDecayPrice(
            auction.startPrice, auction.endPrice, auction.startTime, auction.duration, block.timestamp
        );

        // ✅ Step 3: Define Access - ADD MISSING PERMISSIONS
        FHE.allowThis(currentPrice);
        FHE.allow(currentPrice, msg.sender);

        // Validate bid with proper permissions
        euint128 remainingSupply = FHE.sub(auction.totalSupply, auction.soldAmount);
        FHE.allowThis(remainingSupply);

        (ebool isValid, euint128 allocation) = AuctionLibrary.validateBid(encBidAmount, currentPrice, remainingSupply);

        // Grant permissions for validation results
        FHE.allowThis(isValid);

        // ✅ Grant comprehensive bid permissions
        FHEPermissions.grantBidPermissions(
            encBidAmount,
            allocation,
            currentPrice,
            msg.sender, // bidder
            auction.token, // token
            address(this) // contract
        );

        // Store bid with proper access control
        bids[auctionId][msg.sender] = BidData({
            bidAmount: encBidAmount,
            allocation: allocation,
            bidder: msg.sender,
            timestamp: block.timestamp,
            settled: false
        });

        bidders[auctionId].push(msg.sender);

        // Track bid for user
        userBids[msg.sender].push(auctionId);

        // Add to bid queue
        auction.bidQueue.enqueue(encBidAmount);

        // Update sold amount with permissions
        euint128 newSoldAmount = FHE.add(auction.soldAmount, allocation);
        FHE.allowThis(newSoldAmount);
        FHE.allow(newSoldAmount, auction.seller);
        auction.soldAmount = newSoldAmount;

        emit BidSubmitted(auctionId, msg.sender, block.timestamp);
    }

    // =============================================================
    //                      HOOK CALLBACKS
    // =============================================================

    function _afterInitialize(address, PoolKey calldata key, uint160, int24)
        internal
        override
        onlyByManager
        returns (bytes4)
    {
        PoolId poolId = key.toId();

        // Initialize auction infrastructure for this pool (following Iceberg pattern)
        poolAuctionCount[poolId] = 0;

        // Set up initial FHE permissions for pool currencies
        euint128 initialAmount = FHE.asEuint128(0);

        // ✅ Grant permissions for future operations
        FHE.allow(initialAmount, Currency.unwrap(key.currency0));
        FHE.allow(initialAmount, Currency.unwrap(key.currency1));
        FHE.allowThis(initialAmount);

        emit PoolInitialized(poolId, Currency.unwrap(key.currency0), Currency.unwrap(key.currency1));

        return BaseHook.afterInitialize.selector;
    }

    function _beforeAddLiquidity(address, PoolKey calldata key, ModifyLiquidityParams calldata params, bytes calldata)
        internal
        override
        onlyByManager
        returns (bytes4)
    {
        PoolId poolId = key.toId();

        // Get active auctions for this pool
        uint256[] memory activeAuctions = getActiveAuctionsForPool(poolId);

        if (activeAuctions.length > 0) {
            // Convert liquidity delta to encrypted value (fixed casting)
            euint128 liquidityDelta = FHE.asEuint128(uint128(uint256(int256(params.liquidityDelta))));

            // ✅ Grant FHE permissions for liquidity operations
            FHE.allowThis(liquidityDelta);
            FHE.allow(liquidityDelta, Currency.unwrap(key.currency0));
            FHE.allow(liquidityDelta, Currency.unwrap(key.currency1));

            for (uint256 i = 0; i < activeAuctions.length; i++) {
                updateAuctionForLiquidityChange(activeAuctions[i], liquidityDelta);
            }

            emit LiquidityAuctionInteraction(poolId, activeAuctions.length);
        }

        return BaseHook.beforeAddLiquidity.selector;
    }

    function _afterSwap(address, PoolKey calldata key, SwapParams calldata params, BalanceDelta delta, bytes calldata)
        internal
        override
        onlyByManager
        returns (bytes4, int128)
    {
        PoolId poolId = key.toId();

        // Update auction state after swap completes (following Iceberg pattern)
        updateAuctionPostSwap(poolId, params, delta);

        // Check if any auctions should be automatically settled
        checkAndTriggerSettlements(poolId);

        return (BaseHook.afterSwap.selector, 0);
    }

    function _beforeSwap(address sender, PoolKey calldata key, SwapParams calldata params, bytes calldata hookData)
        internal
        override
        onlyByManager
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        PoolId poolId = key.toId();

        // Check for auction-specific operations via hookData
        if (hookData.length > 0) {
            return processAuctionSwap(sender, key, params, hookData);
        }

        // Check for active auctions that might be affected by this swap
        uint256[] memory activeAuctions = getActiveAuctionsForPool(poolId);

        if (activeAuctions.length > 0) {
            return validateSwapAgainstAuctions(sender, key, params, activeAuctions);
        }

        // Regular swap with no auction interaction
        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    function processAuctionSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        bytes calldata hookData
    ) internal returns (bytes4, BeforeSwapDelta, uint24) {
        // Decode auction ID from hookData
        uint256 auctionId = abi.decode(hookData, (uint256));
        DutchAuctionData storage auction = auctions[auctionId];

        if (auction.seller == address(0)) revert AuctionNotFound();

        // ✅ Grant FHE permissions for swap-auction integration
        FHE.allowThis(auction.soldAmount);
        FHE.allowThis(auction.totalSupply);
        FHE.allowThis(auction.startPrice);
        FHE.allowThis(auction.endPrice);
        FHE.allowThis(auction.isActive);

        // Check if swap should trigger settlement
        ebool shouldSettle = checkAuctionSettlementCondition(auctionId);
        FHE.allowThis(shouldSettle);

        // Note: Settlement condition check - in production, this would use FHE operations
        // For now, we'll use a simplified approach without direct decryption
        // TODO: Implement proper FHE-based condition checking

        // Calculate any swap modifications based on auction state
        BeforeSwapDelta delta = calculateAuctionSwapDelta(auctionId, params);

        emit AuctionSwapProcessed(auctionId, sender);

        return (BaseHook.beforeSwap.selector, delta, 0);
    }

    function validateSwapAgainstAuctions(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        uint256[] memory activeAuctions
    ) internal returns (bytes4, BeforeSwapDelta, uint24) {
        // Convert swap amount to encrypted value for validation
        euint128 swapAmount = FHE.asEuint128(uint128(uint256(int256(params.amountSpecified))));

        // ✅ Grant FHE permissions for validation
        FHE.allowThis(swapAmount);
        FHE.allow(swapAmount, sender);

        for (uint256 i = 0; i < activeAuctions.length; i++) {
            uint256 auctionId = activeAuctions[i];

            // Validate swap doesn't exceed auction limits
            euint128 maxAllowed = getMaxSwapAmountForAuction(auctionId);
            FHE.allowThis(maxAllowed);

            ebool isValid = FHE.lte(swapAmount, maxAllowed);
            FHE.allowThis(isValid);

            // Note: In production, validation would use FHE operations
            // For now, we'll skip direct decryption validation
            // TODO: Implement proper FHE-based validation
        }

        emit SwapValidatedAgainstAuctions(key.toId(), activeAuctions.length);

        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    function checkAuctionSettlementCondition(uint256 auctionId) internal returns (ebool) {
        DutchAuctionData storage auction = auctions[auctionId];

        // Check if auction has reached its end time
        euint64 currentTime = FHE.asEuint64(block.timestamp);
        euint64 endTime = FHE.add(auction.startTime, auction.duration);

        FHE.allowThis(currentTime);
        FHE.allowThis(endTime);

        ebool timeExpired = FHE.gte(currentTime, endTime);

        // Check if auction is fully sold
        ebool fullySold = FHE.gte(auction.soldAmount, auction.totalSupply);

        // Should settle if time expired OR fully sold
        return FHE.or(timeExpired, fullySold);
    }

    function calculateAuctionSwapDelta(uint256 auctionId, SwapParams calldata params)
        internal
        pure
        returns (BeforeSwapDelta)
    {
        // For now, return zero delta
        // In advanced implementation, could modify swap amounts based on auction state
        return BeforeSwapDeltaLibrary.ZERO_DELTA;
    }

    function getMaxSwapAmountForAuction(uint256 auctionId) internal returns (euint128) {
        DutchAuctionData storage auction = auctions[auctionId];

        // Calculate remaining supply as max swap amount
        euint128 remaining = FHE.sub(auction.totalSupply, auction.soldAmount);
        FHE.allowThis(remaining);

        return remaining;
    }

    // =============================================================
    //                      HELPER FUNCTIONS
    // =============================================================

    function getActiveAuctionsForPool(PoolId poolId) internal view returns (uint256[] memory) {
        return poolActiveAuctions[poolId];
    }

    function updateAuctionForLiquidityChange(uint256 auctionId, euint128 liquidityDelta) internal {
        DutchAuctionData storage auction = auctions[auctionId];

        // Grant permissions for auction updates
        FHE.allowThis(auction.startPrice);
        FHE.allowThis(auction.endPrice);
        FHE.allowThis(liquidityDelta);

        // Adjust auction parameters based on liquidity change
        // This is a simplified adjustment - could be more sophisticated
        euint128 priceAdjustment = FHE.div(liquidityDelta, FHE.asEuint128(1000));
        euint128 adjustedStartPrice = FHE.add(auction.startPrice, priceAdjustment);

        FHE.allowThis(adjustedStartPrice);
        FHE.allow(adjustedStartPrice, auction.seller);

        // Update with new price
        auction.startPrice = adjustedStartPrice;
    }

    function updateAuctionPostSwap(PoolId poolId, SwapParams calldata, /* params */ BalanceDelta delta) internal {
        uint256[] memory activeAuctions = getActiveAuctionsForPool(poolId);

        if (activeAuctions.length > 0) {
            // Convert delta amounts to encrypted values
            euint128 amount0Delta = FHE.asEuint128(uint128(uint256(int256(delta.amount0()))));
            euint128 amount1Delta = FHE.asEuint128(uint128(uint256(int256(delta.amount1()))));

            // ✅ Grant FHE permissions for delta operations
            FHE.allowThis(amount0Delta);
            FHE.allowThis(amount1Delta);

            for (uint256 i = 0; i < activeAuctions.length; i++) {
                updateAuctionPricing(activeAuctions[i], amount0Delta, amount1Delta);
            }

            emit PostSwapAuctionUpdate(poolId, activeAuctions.length);
        }
    }

    function updateAuctionPricing(uint256 auctionId, euint128 amount0Delta, euint128 amount1Delta) internal {
        DutchAuctionData storage auction = auctions[auctionId];

        // Grant permissions for price updates
        FHE.allowThis(auction.startPrice);
        FHE.allowThis(auction.endPrice);

        // Calculate price impact from swap (simplified)
        euint128 totalSwapImpact = FHE.add(amount0Delta, amount1Delta);
        euint128 priceImpact = FHE.div(totalSwapImpact, FHE.asEuint128(10000));

        FHE.allowThis(priceImpact);
        FHE.allow(priceImpact, auction.seller);

        // Apply minor price adjustment
        euint128 adjustedPrice = FHE.add(auction.startPrice, priceImpact);
        FHE.allowThis(adjustedPrice);
        FHE.allow(adjustedPrice, auction.seller);

        auction.startPrice = adjustedPrice;
    }

    function checkAndTriggerSettlements(PoolId poolId) internal {
        uint256[] memory activeAuctions = getActiveAuctionsForPool(poolId);

        for (uint256 i = 0; i < activeAuctions.length; i++) {
            uint256 auctionId = activeAuctions[i];

            if (shouldAutoSettle(auctionId)) {
                // Trigger automatic settlement
                _settleAuctionInternal(auctionId);
            }
        }
    }

    function shouldAutoSettle(uint256 auctionId) internal view returns (bool) {
        DutchAuctionData storage auction = auctions[auctionId];

        // Simple settlement condition - could be more sophisticated
        // Note: In production, this would use FHE time comparison
        // For now, using simplified approach
        // TODO: Implement proper FHE-based time checking
        return false;
    }

    /// @notice Add auction to pool tracking
    function addAuctionToPool(PoolId poolId, uint256 auctionId) internal {
        poolAuctionCount[poolId] += 1;
        poolActiveAuctions[poolId].push(auctionId);
    }

    /// @notice Remove auction from pool tracking
    function removeAuctionFromPool(PoolId poolId, uint256 auctionId) internal {
        uint256[] storage activeAuctions = poolActiveAuctions[poolId];

        for (uint256 i = 0; i < activeAuctions.length; i++) {
            if (activeAuctions[i] == auctionId) {
                // Swap with last element and pop
                activeAuctions[i] = activeAuctions[activeAuctions.length - 1];
                activeAuctions.pop();
                break;
            }
        }
    }

    // =============================================================
    //                      SETTLEMENT
    // =============================================================

    function settleAuction(uint256 auctionId) external nonReentrant {
        _settleAuctionInternal(auctionId);
    }

    function _settleAuctionInternal(uint256 auctionId) internal {
        DutchAuctionData storage auction = auctions[auctionId];

        if (auction.seller == address(0)) revert AuctionNotFound();

        // ✅ Grant comprehensive settlement permissions
        FHE.allowThis(auction.soldAmount);
        FHE.allowThis(auction.totalSupply);
        FHE.allow(auction.soldAmount, auction.seller);
        FHE.allow(auction.totalSupply, auction.seller);

        // Calculate final settlement amounts
        euint128 totalSold = auction.soldAmount;
        euint128 remainingSupply = FHE.sub(auction.totalSupply, totalSold);

        // Grant permissions for settlement calculations
        FHEPermissions.grantSettlementPermissions(
            totalSold, remainingSupply, auction.seller, auction.token, address(this)
        );

        // Mark auction as inactive
        ebool inactiveStatus = FHE.asEbool(false);
        FHE.allowThis(inactiveStatus);
        auction.isActive = inactiveStatus;

        // Process all bids with proper FHE permissions
        address[] memory auctionBidders = bidders[auctionId];

        for (uint256 i = 0; i < auctionBidders.length; i++) {
            settleBidWithFhe(auctionId, auctionBidders[i]);
        }

        // Remove from pool tracking
        removeAuctionFromPool(auction.poolId, auctionId);

        // Request decryption and emit with placeholder for now
        FHE.decrypt(auction.soldAmount);
        emit AuctionSettled(auctionId, 0, auctionBidders.length);
    }

    function settleBidWithFhe(uint256 auctionId, address bidder) internal {
        BidData storage bid = bids[auctionId][bidder];
        DutchAuctionData storage auction = auctions[auctionId];

        if (bid.settled) return;

        // ✅ Grant permissions for individual bid settlement
        FHE.allow(bid.allocation, auction.token);
        FHE.allow(bid.allocation, bidder);
        FHE.allowThis(bid.allocation);
        FHE.allow(bid.bidAmount, bidder);
        FHE.allowThis(bid.bidAmount);

        // Execute encrypted token transfer using IFHERC20
        IFHERC20(auction.token).transferFromEncrypted(
            address(this),
            bidder,
            bid.allocation
        );

        bid.settled = true;
        emit BidSettled(auctionId, bidder, block.timestamp);
    }

    // =============================================================
    //                    PARAMETER REVEAL
    // =============================================================

    function revealParameters(uint256 auctionId) external {
        DutchAuctionData storage auction = auctions[auctionId];

        if (auction.seller != msg.sender) revert UnauthorizedSeller();

        auction.parametersRevealed = true;

        // Request decryption for parameters
        FHE.decrypt(auction.startPrice);
        FHE.decrypt(auction.endPrice);
        FHE.decrypt(auction.duration);

        // In production, this would be handled asynchronously
        emit ParametersRevealed(auctionId, 0, 0, 0);
    }

    // =============================================================
    //                    VIEW FUNCTIONS
    // =============================================================

    function getCurrentPrice(uint256 auctionId) external view returns (uint256) {
        // In production, this would check if price has been decrypted
        // For now, return a placeholder
        return 0;
    }

    function getAuctionInfo(uint256 auctionId)
        external
        view
        returns (address seller, address token, bool isActive, bool revealed, uint256 bidderCount, uint256 queueLength)
    {
        DutchAuctionData storage auction = auctions[auctionId];
        return (
            auction.seller,
            auction.token,
            true, // Placeholder for isActive
            auction.parametersRevealed,
            bidders[auctionId].length,
            auction.bidQueue.length()
        );
    }

    function isAuctionActive(uint256 auctionId) external view returns (bool) {
        // In production, this would check decrypted state
        // For now, return placeholder
        return true;
    }
}
