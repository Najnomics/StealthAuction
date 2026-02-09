// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {StealthAuction} from "../src/StealthAuction.sol";
import {StealthAuctionToken} from "../src/StealthAuctionToken.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";

// FHE Imports
import {InEuint128, InEuint64} from "@fhenixprotocol/cofhe-contracts/FHE.sol";
import {CoFheTest} from "@fhenixprotocol/cofhe-mock-contracts/CoFheTest.sol";

/// @notice Full workflow simulation for StealthAuction using FHE mocks.
/// @dev    Uses vm.startPrank (not vm.startBroadcast) so the entire flow runs
///         in the local fork simulation with mock FHE infrastructure.
///         Run with: forge script script/StealthAuctionFlow.s.sol --fork-url $RPC_URL -vvvv
contract StealthAuctionFlow is Script, CoFheTest {
    using PoolIdLibrary for PoolKey;

    struct FlowConfig {
        uint256 supply;
        uint256 startPrice;
        uint256 endPrice;
        uint256 duration;
        uint256 decayRate;
    }

    function run() external {
        // Allow cheatcodes for FHE mock contracts deployed by CoFheTest
        // (scripts don't grant cheatcode access automatically like tests do)
        vm.allowCheatcodes(ZK_VERIFIER_SIGNER_ADDRESS);
        vm.allowCheatcodes(ZK_VERIFIER_ADDRESS);

        address hookAddr = vm.envAddress("STEALTH_AUCTION_HOOK");
        address auctionToken = vm.envAddress("AUCTION_TOKEN");
        address token0 = vm.envAddress("TOKEN0");
        address token1 = vm.envAddress("TOKEN1");

        uint256 sellerPk = vm.envUint("PRIVATE_KEY");
        address seller = vm.addr(sellerPk);

        PoolId poolId = _computePoolId(hookAddr, token0, token1);
        FlowConfig memory cfg = FlowConfig({
            supply: 1000 ether,
            startPrice: 10 ether,
            endPrice: 1 ether,
            duration: 3600,
            decayRate: 100
        });

        console.log("=== StealthAuction Flow Test ===");
        console.log("Seller:", seller);
        console.log("Hook:", hookAddr);
        console.log("Auction token:", auctionToken);
        console.log("PoolId:", vm.toString(PoolId.unwrap(poolId)));

        _initializeAuctionSupply(auctionToken, hookAddr, seller, cfg.supply);
        uint256 auctionId = _createAuction(hookAddr, auctionToken, poolId, seller, cfg);
        _submitBids(hookAddr, auctionId);
        _settleAndReveal(hookAddr, auctionId, seller);

        console.log("=== Flow Complete ===");
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

    function _initializeAuctionSupply(address auctionToken, address hookAddr, address seller, uint256 supply)
        internal
    {
        InEuint128 memory encSupply = createInEuint128(uint128(supply), seller);

        vm.startPrank(seller);
        StealthAuctionToken(auctionToken).initializeAuctionSupply(hookAddr, encSupply);
        StealthAuctionToken(auctionToken).approve(hookAddr, type(uint256).max);
        vm.stopPrank();
    }

    function _createAuction(
        address hookAddr,
        address auctionToken,
        PoolId poolId,
        address seller,
        FlowConfig memory cfg
    ) internal returns (uint256 auctionId) {
        InEuint128 memory encStartPrice = createInEuint128(uint128(cfg.startPrice), seller);
        InEuint128 memory encEndPrice = createInEuint128(uint128(cfg.endPrice), seller);
        InEuint64 memory encDuration = createInEuint64(uint64(cfg.duration), seller);
        InEuint128 memory encSupply = createInEuint128(uint128(cfg.supply), seller);

        vm.startPrank(seller);
        auctionId = StealthAuction(hookAddr).createEncryptedAuction(
            poolId,
            auctionToken,
            encStartPrice,
            encEndPrice,
            encDuration,
            encSupply,
            cfg.decayRate
        );
        vm.stopPrank();

        console.log("Auction created:", auctionId);
    }

    function _submitBids(address hookAddr, uint256 auctionId) internal {
        (bool ok1, uint256 bidder1Pk) = _loadOptionalPk("BIDDER1_PRIVATE_KEY");
        (bool ok2, uint256 bidder2Pk) = _loadOptionalPk("BIDDER2_PRIVATE_KEY");

        if (ok1 && bidder1Pk != 0) {
            _submitBid(hookAddr, auctionId, vm.addr(bidder1Pk), 8 ether);
        } else {
            console.log("Skipping bidder1: BIDDER1_PRIVATE_KEY not set");
        }

        if (ok2 && bidder2Pk != 0) {
            _submitBid(hookAddr, auctionId, vm.addr(bidder2Pk), 6 ether);
        } else {
            console.log("Skipping bidder2: BIDDER2_PRIVATE_KEY not set");
        }

        if (!ok1 && !ok2) {
            console.log("No bidder keys provided; no bids submitted.");
        }
    }

    function _submitBid(address hookAddr, uint256 auctionId, address bidder, uint256 amount) internal {
        InEuint128 memory encBid = createInEuint128(uint128(amount), bidder);

        vm.startPrank(bidder);
        StealthAuction(hookAddr).submitEncryptedBid(auctionId, encBid);
        vm.stopPrank();

        console.log("Bid submitted:", bidder);
        console.log("Bid amount (ETH):", amount / 1e18);
    }

    function _settleAndReveal(address hookAddr, uint256 auctionId, address seller) internal {
        vm.startPrank(seller);
        StealthAuction(hookAddr).settleAuction(auctionId);
        StealthAuction(hookAddr).revealParameters(auctionId);
        vm.stopPrank();
        console.log("Auction settled and parameters revealed");
    }

    function _loadOptionalPk(string memory key) internal returns (bool ok, uint256 pk) {
        try vm.envUint(key) returns (uint256 value) {
            return (true, value);
        } catch {
            return (false, 0);
        }
    }
}
