// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {AuctionToken} from "../../src/AuctionToken.sol";

/// @notice Shared configuration between scripts
contract Config {
    /// @dev Populated with deployed addresses per chain
    AuctionToken immutable AUCTION_TOKEN;
    AuctionToken immutable BASE_TOKEN;
    IHooks immutable HOOK_CONTRACT;

    Currency immutable AUCTION_CURRENCY;
    Currency immutable BASE_CURRENCY;

    constructor() {
        if (block.chainid == 31337) {
            // Anvil - deployed addresses
            AUCTION_TOKEN = AuctionToken(address(0x5FbDB2315678afecb367f032d93F642f64180aa3));
            BASE_TOKEN = AuctionToken(address(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512));
            HOOK_CONTRACT = IHooks(address(0x781D0CE33a3E397A523a47Ef2936352b8Ba4C080));
            AUCTION_CURRENCY = Currency.wrap(address(AUCTION_TOKEN));
            BASE_CURRENCY = Currency.wrap(address(BASE_TOKEN));
        } else if (block.chainid == 11155111) {
            // Ethereum Sepolia
            AUCTION_TOKEN = AuctionToken(address(0x0eA00720cAA3b6A5d18683D09A75E8425934529c));
            BASE_TOKEN = AuctionToken(address(0xBA131d183F67dD1B4252487681b598B6bC165D17));
            HOOK_CONTRACT = IHooks(address(0x5487bfA4195EB06d0084e3B5Cb52970396C350c0));
            AUCTION_CURRENCY = Currency.wrap(address(AUCTION_TOKEN));
            BASE_CURRENCY = Currency.wrap(address(BASE_TOKEN));
        } else if (block.chainid == 8008135) {
            // Fhenix Helium
            AUCTION_TOKEN = AuctionToken(address(0x0eA00720cAA3b6A5d18683D09A75E8425934529c));
            BASE_TOKEN = AuctionToken(address(0xBA131d183F67dD1B4252487681b598B6bC165D17));
            HOOK_CONTRACT = IHooks(address(0x5487bfA4195EB06d0084e3B5Cb52970396C350c0));
            AUCTION_CURRENCY = Currency.wrap(address(AUCTION_TOKEN));
            BASE_CURRENCY = Currency.wrap(address(BASE_TOKEN));
        } else {
            revert("Config: unsupported chain");
        }
    }
}
