// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {AuctionToken} from "../../src/AuctionToken.sol";

/// @notice Shared configuration between scripts
contract Config {
    /// @dev Populated with deployed addresses per chain
    AuctionToken immutable auctionToken;
    AuctionToken immutable baseToken;
    IHooks immutable hookContract;

    Currency immutable auctionCurrency;
    Currency immutable baseCurrency;

    constructor() {
        if (block.chainid == 31337) {
            // Anvil - deployed addresses
            auctionToken = AuctionToken(address(0x5FbDB2315678afecb367f032d93F642f64180aa3));
            baseToken = AuctionToken(address(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512));
            hookContract = IHooks(address(0x781D0CE33a3E397A523a47Ef2936352b8Ba4C080));
            auctionCurrency = Currency.wrap(address(auctionToken));
            baseCurrency = Currency.wrap(address(baseToken));
        } else if (block.chainid == 11155111) {
            // Ethereum Sepolia
            auctionToken = AuctionToken(address(0x0eA00720cAA3b6A5d18683D09A75E8425934529c));
            baseToken = AuctionToken(address(0xBA131d183F67dD1B4252487681b598B6bC165D17));
            hookContract = IHooks(address(0x5487bfA4195EB06d0084e3B5Cb52970396C350c0));
            auctionCurrency = Currency.wrap(address(auctionToken));
            baseCurrency = Currency.wrap(address(baseToken));
        } else if (block.chainid == 8008135) {
            // Fhenix Helium
            auctionToken = AuctionToken(address(0x0eA00720cAA3b6A5d18683D09A75E8425934529c));
            baseToken = AuctionToken(address(0xBA131d183F67dD1B4252487681b598B6bC165D17));
            hookContract = IHooks(address(0x5487bfA4195EB06d0084e3B5Cb52970396C350c0));
            auctionCurrency = Currency.wrap(address(auctionToken));
            baseCurrency = Currency.wrap(address(baseToken));
        } else {
            revert("Config: unsupported chain");
        }
    }
}
