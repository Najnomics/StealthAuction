// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {Constants} from "./base/Constants.sol";
import {AuctionToken} from "../src/AuctionToken.sol";

/// @notice Deploys auction tokens for testing and demos
contract DeployTokensScript is Script, Constants {
    function setUp() public {}

    function run() public returns (AuctionToken auctionToken, AuctionToken baseToken) {
        console.log("Deploying Auction Tokens...");
        console.log("Chain ID:", block.chainid);
        console.log("Deployer:", msg.sender);

        vm.startBroadcast();

        // Deploy auction token (what's being sold in auctions)
        auctionToken = new AuctionToken("Auction Token", "AUCT", 18);
        
        // Deploy base token (what bidders pay with - like USDC/ETH)
        baseToken = new AuctionToken("Base Token", "BASE", 18);

        // Mint initial supply to deployer
        auctionToken.mint(msg.sender, 10_000_000 ether);
        baseToken.mint(msg.sender, 10_000_000 ether);

        vm.stopBroadcast();

        console.log("AuctionToken deployed at:", address(auctionToken));
        console.log("BaseToken deployed at:", address(baseToken));
        console.log("Initial supply minted to:", msg.sender);

        return (auctionToken, baseToken);
    }

    /// @notice Deploy tokens and return sorted pair
    function runSorted() public returns (AuctionToken token0, AuctionToken token1) {
        (AuctionToken auctionToken, AuctionToken baseToken) = run();
        
        // Sort tokens for Uniswap v4 compatibility
        if (address(auctionToken) < address(baseToken)) {
            token0 = auctionToken;
            token1 = baseToken;
        } else {
            token0 = baseToken;
            token1 = auctionToken;
        }

        console.log("Sorted tokens:");
        console.log("  Token0:", address(token0));
        console.log("  Token1:", address(token1));

        return (token0, token1);
    }
}
