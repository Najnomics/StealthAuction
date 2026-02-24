// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {StealthAuction} from "../src/StealthAuction.sol";
import {StealthAuctionToken} from "../src/StealthAuctionToken.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {InEuint128, InEuint64} from "@fhenixprotocol/cofhe-contracts/FHE.sol";

/// @notice Production/Base Sepolia flow using pre-encrypted InEuint payloads.
/// @dev No CoFheTest helpers are used in this script.
contract StealthAuctionSepoliaFlow is Script {
    using PoolIdLibrary for PoolKey;

    function run() external {
        address hookAddr = vm.envAddress("STEALTH_AUCTION_HOOK");
        address auctionToken = vm.envAddress("AUCTION_TOKEN");
        address token0 = vm.envAddress("TOKEN0");
        address token1 = vm.envAddress("TOKEN1");

        uint256 sellerPk = vm.envUint("PRIVATE_KEY");
        uint256 ownerPk = _optionalPk("OWNER_PRIVATE_KEY", sellerPk);
        // intentionally reversed order to test the script
        uint256 bidder2Pk = vm.envUint("BIDDER1_PRIVATE_KEY");
        // intentionally reversed order to test the script
        uint256 bidder1Pk = vm.envUint("BIDDER2_PRIVATE_KEY");

        address seller = vm.addr(sellerPk);
        PoolId poolId = _computePoolId(hookAddr, token0, token1);

        InEuint128 memory tokenSupply = _load128("ENC_TOKEN_SUPPLY");
        InEuint128 memory startPrice = _load128("ENC_START_PRICE");
        InEuint128 memory endPrice = _load128("ENC_END_PRICE");
        InEuint64 memory duration = _load64("ENC_DURATION");
        InEuint128 memory auctionSupply = _load128("ENC_AUCTION_SUPPLY");
        InEuint128 memory bid1 = _load128("ENC_BID1");
        InEuint128 memory bid2 = _load128("ENC_BID2");

        uint256 decayRate = vm.envUint("DECAY_RATE");

        console.log("=== StealthAuction Sepolia Flow ===");
        console.log("Seller:", seller);
        console.log("Hook:", hookAddr);
        console.log("Auction token:", auctionToken);
        console.log("PoolId:", vm.toString(PoolId.unwrap(poolId)));

        vm.startBroadcast(ownerPk);
        StealthAuctionToken(auctionToken).initializeAuctionSupply(hookAddr, tokenSupply);
        vm.stopBroadcast();

        vm.startBroadcast(sellerPk);
        StealthAuctionToken(auctionToken).approve(hookAddr, type(uint256).max);
        uint256 auctionId = StealthAuction(hookAddr)
            .createEncryptedAuction(poolId, auctionToken, startPrice, endPrice, duration, auctionSupply, decayRate);
        vm.stopBroadcast();
        console.log("Auction created:", auctionId);

        vm.startBroadcast(bidder1Pk);
        StealthAuction(hookAddr).submitEncryptedBid(auctionId, bid1);
        vm.stopBroadcast();
        console.log("Bid 1 submitted by:", vm.addr(bidder1Pk));

        vm.startBroadcast(bidder2Pk);
        StealthAuction(hookAddr).submitEncryptedBid(auctionId, bid2);
        vm.stopBroadcast();
        console.log("Bid 2 submitted by:", vm.addr(bidder2Pk));

        vm.startBroadcast(sellerPk);
        StealthAuction(hookAddr).settleAuction(auctionId);
        StealthAuction(hookAddr).revealParameters(auctionId);
        vm.stopBroadcast();

        console.log("Auction settled and revealed");
        console.log("=== Sepolia Flow Complete ===");
    }

    function _computePoolId(address hookAddr, address token0, address token1) internal pure returns (PoolId) {
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(hookAddr)
        });
        return key.toId();
    }

    function _load128(string memory prefix) internal returns (InEuint128 memory value) {
        value = InEuint128({
            ctHash: vm.envUint(string.concat(prefix, "_CTHASH")),
            securityZone: uint8(vm.envUint(string.concat(prefix, "_SECURITY_ZONE"))),
            utype: uint8(vm.envUint(string.concat(prefix, "_UTYPE"))),
            signature: vm.envBytes(string.concat(prefix, "_SIGNATURE"))
        });
    }

    function _load64(string memory prefix) internal returns (InEuint64 memory value) {
        value = InEuint64({
            ctHash: vm.envUint(string.concat(prefix, "_CTHASH")),
            securityZone: uint8(vm.envUint(string.concat(prefix, "_SECURITY_ZONE"))),
            utype: uint8(vm.envUint(string.concat(prefix, "_UTYPE"))),
            signature: vm.envBytes(string.concat(prefix, "_SIGNATURE"))
        });
    }

    function _optionalPk(string memory key, uint256 fallbackValue) internal returns (uint256) {
        try vm.envUint(key) returns (uint256 value) {
            return value;
        } catch {
            return fallbackValue;
        }
    }
}
