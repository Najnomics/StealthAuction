// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {FHE, InEuint128, euint128} from "@fhenixprotocol/cofhe-contracts/FHE.sol";

/**
 * @title IFHERC20
 * @notice Interface for FHE-enabled ERC20 tokens with encrypted balance support
 * @dev Based on Fhenix protocol patterns for auction-specific token operations
 */
interface IFHERC20 {
    // -------- Encrypted Mint Functions --------
    function mintEncrypted(address user, InEuint128 memory amount) external;
    function mintEncrypted(address user, euint128 amount) external;

    // -------- Encrypted Burn Functions --------
    function burnEncrypted(address user, InEuint128 memory amount) external;
    function burnEncrypted(address user, euint128 amount) external;

    // -------- Encrypted Transfer Functions --------
    function transferEncrypted(address to, InEuint128 memory amount) external returns (euint128);
    function transferEncrypted(address to, euint128 amount) external returns (euint128);
    function transferFromEncrypted(address from, address to, InEuint128 memory amount) external returns (euint128);
    function transferFromEncrypted(address from, address to, euint128 amount) external returns (euint128);

    // -------- Encrypted Balance Functions --------
    function encBalances(address user) external view returns (euint128);
    function totalEncryptedSupply() external view returns (euint128);

    // -------- Auction-Specific Functions --------
    function initializeAuctionSupply(address auctionContract, InEuint128 memory amount) external;
    function initializeAuctionSupply(address auctionContract, euint128 amount) external;

    // -------- Decrypt Balance Functions --------
    function decryptBalance(address user) external;
    function getDecryptBalanceResult(address user) external view returns (uint128);
    function getDecryptBalanceResultSafe(address user) external view returns (uint128, bool);

    // -------- Encrypted Wrapping Functions --------
    function wrap(address user, uint128 amount) external;

    // -------- Encrypted Unwrapping Functions --------
    function requestUnwrap(address user, InEuint128 memory amount) external returns (euint128);
    function requestUnwrap(address user, euint128 amount) external returns (euint128);
    function getUnwrapResult(address user, euint128 burnAmount) external returns (uint128 amount);
    function getUnwrapResultSafe(address user, euint128 burnAmount) external returns (uint128 amount, bool decrypted);
}
