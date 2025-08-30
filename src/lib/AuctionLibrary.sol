// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {FHE, euint128, euint64, ebool} from "@fhenixprotocol/cofhe-contracts/FHE.sol";

/// @title AuctionLibrary
/// @notice Library for encrypted Dutch auction price calculations and utilities
library AuctionLibrary {
    
    /// @notice Calculate current price with linear decay
    /// @param startPrice Encrypted starting price
    /// @param endPrice Encrypted ending price
    /// @param startTime Encrypted start timestamp
    /// @param duration Encrypted auction duration
    /// @param currentTime Current block timestamp
    /// @return currentPrice The calculated encrypted current price
    function calculateLinearDecayPrice(
        euint128 startPrice,
        euint128 endPrice,
        euint64 startTime,
        euint64 duration,
        uint256 currentTime
    ) internal returns (euint128 currentPrice) {
        euint64 encCurrentTime = FHE.asEuint64(currentTime);
        euint64 elapsed = FHE.sub(encCurrentTime, startTime);

        // Check if auction has ended
        ebool auctionEnded = FHE.gte(elapsed, duration);

        // Calculate linear decay
        euint128 priceDiff = FHE.sub(startPrice, endPrice);
        euint128 elapsedAs128 = FHE.asEuint128(elapsed);
        euint128 durationAs128 = FHE.asEuint128(duration);
        
        // Calculate decay amount: (priceDiff * elapsed) / duration
        euint128 decay = FHE.div(FHE.mul(priceDiff, elapsedAs128), durationAs128);
        currentPrice = FHE.sub(startPrice, decay);

        // Return end price if auction ended, otherwise current price
        currentPrice = FHE.select(auctionEnded, endPrice, currentPrice);
    }

    /// @notice Calculate current price with exponential decay
    /// @param startPrice Encrypted starting price
    /// @param endPrice Encrypted ending price
    /// @param startTime Encrypted start timestamp
    /// @param duration Encrypted auction duration
    /// @param decayRate Decay rate factor
    /// @param currentTime Current block timestamp
    /// @return currentPrice The calculated encrypted current price
    function calculateExponentialDecayPrice(
        euint128 startPrice,
        euint128 endPrice,
        euint64 startTime,
        euint64 duration,
        uint256 decayRate,
        uint256 currentTime
    ) internal returns (euint128 currentPrice) {
        euint64 encCurrentTime = FHE.asEuint64(currentTime);
        euint64 elapsed = FHE.sub(encCurrentTime, startTime);

        // Check if auction has ended
        ebool auctionEnded = FHE.gte(elapsed, duration);

        // Simplified exponential decay approximation
        // price = startPrice * (decayRate^(elapsed/duration))
        euint128 priceDiff = FHE.sub(startPrice, endPrice);
        euint128 elapsedAs128 = FHE.asEuint128(elapsed);
        euint128 durationAs128 = FHE.asEuint128(duration);
        
        // Approximation: exponential ~ (1 - elapsed/duration)^decayRate
        euint128 decayFactor = FHE.div(elapsedAs128, durationAs128);
        euint128 decay = FHE.mul(priceDiff, decayFactor);
        currentPrice = FHE.sub(startPrice, decay);

        // Ensure price doesn't go below end price
        currentPrice = FHE.max(currentPrice, endPrice);
        
        // Return end price if auction ended, otherwise current price
        currentPrice = FHE.select(auctionEnded, endPrice, currentPrice);
    }

    /// @notice Validate bid against current price and supply
    /// @param bidAmount Encrypted bid amount
    /// @param currentPrice Encrypted current price
    /// @param remainingSupply Encrypted remaining supply
    /// @return isValid Whether the bid is valid
    /// @return allocation Calculated token allocation
    function validateBid(
        euint128 bidAmount,
        euint128 currentPrice,
        euint128 remainingSupply
    ) internal returns (ebool isValid, euint128 allocation) {
        // Check if bid meets price requirement
        ebool bidMeetsPrice = FHE.gte(bidAmount, currentPrice);

        // Check if there's supply available
        ebool hasSupply = FHE.gt(remainingSupply, FHE.asEuint128(0));

        // Calculate allocation (bid amount / current price)
        allocation = FHE.div(bidAmount, currentPrice);

        // Limit allocation to remaining supply
        ebool allocationExceedsSupply = FHE.gt(allocation, remainingSupply);
        allocation = FHE.select(allocationExceedsSupply, remainingSupply, allocation);

        // Valid if bid meets price AND there's supply
        isValid = FHE.and(bidMeetsPrice, hasSupply);

        // Zero allocation if invalid
        allocation = FHE.select(isValid, allocation, FHE.asEuint128(0));
    }

    /// @notice Calculate total value for a given allocation
    /// @param allocation Token allocation amount
    /// @param price Price per token
    /// @return totalValue Total value of the allocation
    function calculateValue(
        euint128 allocation,
        euint128 price
    ) internal returns (euint128 totalValue) {
        totalValue = FHE.mul(allocation, price);
    }

    /// @notice Check if auction is still active
    /// @param startTime Encrypted start time
    /// @param duration Encrypted duration
    /// @param currentTime Current timestamp
    /// @return isActive Whether auction is still active
    function isAuctionActive(
        euint64 startTime,
        euint64 duration,
        uint256 currentTime
    ) internal returns (ebool isActive) {
        euint64 encCurrentTime = FHE.asEuint64(currentTime);
        euint64 elapsed = FHE.sub(encCurrentTime, startTime);
        isActive = FHE.lt(elapsed, duration);
    }
}
