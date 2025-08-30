// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {FHE, euint128, euint64, ebool} from "@fhenixprotocol/cofhe-contracts/FHE.sol";

/// @title FHE Permission Management Library
/// @notice Centralizes FHE.allow() calls for consistent access control
/// @dev This library implements the critical "Define Access" step in Fhenix's 3-step CoFHE pattern
library FHEPermissions {
    
    /// @notice Grant comprehensive permissions for auction creation
    /// @param startPrice Encrypted starting price
    /// @param endPrice Encrypted ending price
    /// @param duration Encrypted auction duration
    /// @param supply Encrypted total supply
    /// @param seller Address of the auction seller
    /// @param token Address of the token contract
    /// @param auctionContract Address of the auction contract
    function grantAuctionCreationPermissions(
        euint128 startPrice,
        euint128 endPrice, 
        euint64 duration,
        euint128 supply,
        address seller,
        address token,
        address auctionContract
    ) internal {
        // Seller permissions - seller needs access to view auction parameters
        FHE.allow(startPrice, seller);
        FHE.allow(endPrice, seller);
        FHE.allow(duration, seller);
        FHE.allow(supply, seller);
        
        // Contract permissions - auction contract needs access for calculations
        FHE.allowThis(startPrice);
        FHE.allowThis(endPrice);
        FHE.allowThis(duration);
        FHE.allowThis(supply);
        
        // Token permissions - token contract needs access for transfers
        FHE.allow(supply, token);
    }
    
    /// @notice Grant permissions for bid operations
    /// @param bidAmount Encrypted bid amount
    /// @param allocation Encrypted token allocation
    /// @param currentPrice Encrypted current auction price
    /// @param bidder Address of the bidder
    /// @param token Address of the token contract
    /// @param auctionContract Address of the auction contract
    function grantBidPermissions(
        euint128 bidAmount,
        euint128 allocation,
        euint128 currentPrice,
        address bidder,
        address token,
        address auctionContract
    ) internal {
        // Bidder permissions - bidder needs access to their bid data
        FHE.allow(bidAmount, bidder);
        FHE.allow(allocation, bidder);
        
        // Contract permissions - auction contract needs access for validation and storage
        FHE.allowThis(bidAmount);
        FHE.allowThis(allocation);
        FHE.allowThis(currentPrice);
        
        // Token permissions - token contract needs access for encrypted transfers
        FHE.allow(allocation, token);
        FHE.allow(bidAmount, token);
    }
    
    /// @notice Grant permissions for settlement operations
    /// @param totalAllocation Total encrypted allocation amount
    /// @param remainingSupply Remaining encrypted supply
    /// @param seller Address of the auction seller
    /// @param token Address of the token contract
    /// @param auctionContract Address of the auction contract
    function grantSettlementPermissions(
        euint128 totalAllocation,
        euint128 remainingSupply,
        address seller,
        address token,
        address auctionContract
    ) internal {
        // Seller permissions - seller needs access to settlement data
        FHE.allow(totalAllocation, seller);
        FHE.allow(remainingSupply, seller);
        
        // Contract permissions - auction contract needs access for calculations
        FHE.allowThis(totalAllocation);
        FHE.allowThis(remainingSupply);
        
        // Token permissions - token contract needs access for final transfers
        FHE.allow(totalAllocation, token);
    }
    
    /// @notice Grant permissions for pool operations
    /// @param amount0 Encrypted amount for currency0
    /// @param amount1 Encrypted amount for currency1
    /// @param currency0 Address of currency0
    /// @param currency1 Address of currency1
    /// @param hookContract Address of the hook contract
    function grantPoolPermissions(
        euint128 amount0,
        euint128 amount1,
        address currency0,
        address currency1,
        address hookContract
    ) internal {
        // Currency permissions - each currency needs access to its amount
        FHE.allow(amount0, currency0);
        FHE.allow(amount1, currency1);
        
        // Hook permissions - hook contract needs access for calculations
        FHE.allowThis(amount0);
        FHE.allowThis(amount1);
    }
    
    /// @notice Grant permissions for swap operations
    /// @param swapAmount Encrypted swap amount
    /// @param maxAllowed Encrypted maximum allowed amount
    /// @param isValid Encrypted validation result
    /// @param sender Address of the swap sender
    /// @param hookContract Address of the hook contract
    function grantSwapPermissions(
        euint128 swapAmount,
        euint128 maxAllowed,
        ebool isValid,
        address sender,
        address hookContract
    ) internal {
        // Sender permissions - sender needs access to swap data
        FHE.allow(swapAmount, sender);
        
        // Hook permissions - hook contract needs access for validation
        FHE.allowThis(swapAmount);
        FHE.allowThis(maxAllowed);
        FHE.allowThis(isValid);
    }
    
    /// @notice Grant permissions for time-based operations
    /// @param startTime Encrypted start time
    /// @param duration Encrypted duration
    /// @param currentTime Encrypted current time
    /// @param user Address of the user
    /// @param contractAddr Address of the contract
    function grantTimePermissions(
        euint64 startTime,
        euint64 duration,
        euint64 currentTime,
        address user,
        address contractAddr
    ) internal {
        // User permissions
        FHE.allow(startTime, user);
        FHE.allow(duration, user);
        
        // Contract permissions
        FHE.allowThis(startTime);
        FHE.allowThis(duration);
        FHE.allowThis(currentTime);
    }
    
    /// @notice Grant permissions for boolean operations
    /// @param boolValue Encrypted boolean value
    /// @param user Address of the user
    /// @param contractAddr Address of the contract
    function grantBoolPermissions(
        ebool boolValue,
        address user,
        address contractAddr
    ) internal {
        FHE.allow(boolValue, user);
        FHE.allowThis(boolValue);
    }
}
