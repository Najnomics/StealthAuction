// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolManager} from "@uniswap/v4-core/src/PoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";

import {StealthAuction} from "../src/StealthAuction.sol";
import {StealthAuctionToken} from "../src/StealthAuctionToken.sol";
import {PoolManagerAddresses} from "./base/PoolManagerAddresses.sol";

/// @title Deployment Script for StealthAuction System
/// @notice Deploys the complete FHE-powered Dutch auction system with proper hook configuration
contract DeployStealthAuction is Script {
    using PoolIdLibrary for PoolKey;

    /// @dev The canonical CREATE2 deployer used by Uniswap / Foundry
    /// @dev Must match the address used when actually deploying via CREATE2
    address internal constant CREATE2_DEPLOYER = address(0x4e59b44847b379578588920cA78FbF26c0B4956C);

    // Deployment configuration
    struct DeploymentConfig {
        address deployer;
        address poolManager;
        string networkName;
        uint256 deployerPrivateKey;
    }

    // Deployment results
    struct DeploymentResult {
        address stealthAuctionHook;
        address token0;
        address token1;
        address auctionToken;
        PoolId poolId;
        PoolKey poolKey;
    }

    // Events for tracking deployment
    event StealthAuctionDeployed(address indexed hook, address indexed poolManager);
    event TokensDeployed(address indexed token0, address indexed token1, address indexed auctionToken);
    event PoolCreated(PoolId indexed poolId, address indexed hook);

    function run() external returns (DeploymentResult memory result) {
        DeploymentConfig memory config = _getDeploymentConfig();

        console.log("Starting StealthAuction deployment on", config.networkName);
        console.log("Deployer (EOA):", config.deployer);
        console.log("Pool Manager (using POOL_MANAGER_ADDRESS or default):", config.poolManager);

        vm.startBroadcast(config.deployerPrivateKey);

        // Step 1: Use existing StealthAuction hook (deployed separately via StealthAuction.s.sol)
        address existingHook = vm.envAddress("STEALTH_AUCTION_HOOK");
        console.log("Using existing StealthAuction hook:", existingHook);
        result.stealthAuctionHook = existingHook;

        // Step 2: Deploy FHE tokens
        (result.token0, result.token1, result.auctionToken) = _deployTokens();

        // Step 3: Create and initialize pool
        (result.poolId, result.poolKey) =
            _createPool(config.poolManager, result.stealthAuctionHook, result.token0, result.token1);

        // Step 4: Setup initial token distributions
        _setupInitialDistribution(result.token0, result.token1, result.auctionToken);

        vm.stopBroadcast();

        // Step 5: Log deployment summary
        _logDeploymentSummary(result);

        return result;
    }

    function _getDeploymentConfig() internal returns (DeploymentConfig memory config) {
        config.deployer = msg.sender;
        config.deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Check for existing PoolManager or deploy new one
        address existingManager = vm.envOr("POOL_MANAGER_ADDRESS", address(0));
        if (existingManager != address(0)) {
            config.poolManager = existingManager;
            console.log("Using existing PoolManager:", existingManager);
        } else {
            // Deploy new PoolManager
            config.poolManager = address(new PoolManager(address(0)));
            console.log("Deployed new PoolManager:", config.poolManager);
        }

        // Determine network
        if (block.chainid == 1) {
            config.networkName = "Ethereum Mainnet";
        } else if (block.chainid == 11155111) {
            config.networkName = "Sepolia Testnet";
        } else if (block.chainid == 31337) {
            config.networkName = "Anvil Local";
        } else {
            config.networkName = "Unknown Network";
        }
    }

    function _deployStealthAuctionHook(address poolManager) internal returns (address hookAddress) {
        console.log("Deploying StealthAuction hook...");

        // Calculate hook address with required flags
        uint160 flags = uint160(Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG | Hooks.BEFORE_ADD_LIQUIDITY_FLAG);

        // Use CREATE2 to deploy hook at calculated address
        bytes memory creationCode = type(StealthAuction).creationCode;
        bytes memory constructorArgs = abi.encode(poolManager);
        bytes memory bytecode = abi.encodePacked(creationCode, constructorArgs);

        // Find salt that gives us the right hook address
        bytes32 salt = _findSalt(flags, bytecode);

        hookAddress = _deployWithSalt(bytecode, salt);

        require(uint160(hookAddress) & ~flags == 0, "Hook address flags mismatch");

        console.log("StealthAuction hook deployed at:", hookAddress);
        emit StealthAuctionDeployed(hookAddress, poolManager);
    }

    function _deployTokens() internal returns (address token0, address token1, address auctionToken) {
        console.log("Deploying FHE tokens...");

        // Deploy tokens
        StealthAuctionToken tokenA = new StealthAuctionToken("Token A", "TOKA");
        StealthAuctionToken tokenB = new StealthAuctionToken("Token B", "TOKB");
        auctionToken = address(new StealthAuctionToken("Auction Token", "AUCT"));

        // Sort tokens for Uniswap v4 compatibility
        if (address(tokenA) < address(tokenB)) {
            token0 = address(tokenA);
            token1 = address(tokenB);
        } else {
            token0 = address(tokenB);
            token1 = address(tokenA);
        }

        console.log("Token0 deployed at:", token0);
        console.log("Token1 deployed at:", token1);
        console.log("Auction token deployed at:", auctionToken);

        emit TokensDeployed(token0, token1, auctionToken);
    }

    function _createPool(address poolManager, address hook, address token0, address token1)
        internal
        returns (PoolId poolId, PoolKey memory key)
    {
        console.log("Creating and initializing pool...");

        key = PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: 3000, // 0.3% fee
            tickSpacing: 60,
            hooks: IHooks(hook)
        });

        poolId = key.toId();

        // Initialize pool at 1:1 price
        uint160 sqrtPriceX96 = 79228162514264337593543950336; // sqrt(1) << 96
        IPoolManager(poolManager).initialize(key, sqrtPriceX96);

        console.log("Pool created with ID:", vm.toString(PoolId.unwrap(poolId)));
        emit PoolCreated(poolId, hook);
    }

    function _setupInitialDistribution(address token0, address token1, address auctionToken) internal {
        console.log("Setting up initial token distribution...");

        // Mint tokens to deployer for testing/demo purposes
        uint256 initialSupply = 1_000_000 * 1e18;

        StealthAuctionToken(token0).mint(msg.sender, initialSupply);
        StealthAuctionToken(token1).mint(msg.sender, initialSupply);
        StealthAuctionToken(auctionToken).mint(msg.sender, initialSupply);

        console.log("Initial tokens minted to deployer:", msg.sender);
        console.log("Amount per token:", initialSupply);
    }

    function _findSalt(uint160 flags, bytes memory bytecode) internal view returns (bytes32) {
        // Follow the Uniswap v4 hook mining pattern: ensure that the deployed hook address
        // has no extra permission bits set beyond those in `flags`. The constructor of
        // StealthAuction (via BaseHook) will additionally validate that the *required*
        // flags are present.
        for (uint256 i = 0; i < 1_000_000; i++) {
            bytes32 salt = bytes32(i);
            address predicted = _predictAddress(bytecode, salt);

            // Valid if the address does not set any bits outside of our desired flags
            if (uint160(predicted) & (~flags) == 0) {
                return salt;
            }
        }
        revert("Could not find valid salt for hook deployment");
    }

    function _predictAddress(bytes memory bytecode, bytes32 salt) internal view returns (address) {
        // Predict the address using the canonical CREATE2 deployer address, matching the
        // behavior of Uniswap v4 and Foundry's create2 helper.
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), CREATE2_DEPLOYER, salt, keccak256(bytecode)));
        return address(uint160(uint256(hash)));
    }

    function _deployWithSalt(bytes memory bytecode, bytes32 salt) internal returns (address deployed) {
        assembly {
            deployed := create2(0, add(bytecode, 32), mload(bytecode), salt)
            if iszero(deployed) { revert(0, 0) }
        }
    }

    function _logDeploymentSummary(DeploymentResult memory result) internal view {
        console.log("\n=== DEPLOYMENT SUMMARY ===");
        console.log("StealthAuction Hook:", result.stealthAuctionHook);
        console.log("Token0:", result.token0);
        console.log("Token1:", result.token1);
        console.log("Auction Token:", result.auctionToken);
        console.log("Pool ID:", vm.toString(PoolId.unwrap(result.poolId)));
        console.log("Network:", block.chainid);
        console.log("Deployer:", msg.sender);
        console.log("===========================\n");
    }

    function getNetworkPoolManager() internal view returns (address) {
        // For now, return a hardcoded address or use a different approach
        // The try-catch with external calls is not supported in this context
        return PoolManagerAddresses.getPoolManagerByChainId(block.chainid);
    }
}
