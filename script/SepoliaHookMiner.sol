// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {PoolManagerAddresses} from "./base/PoolManagerAddresses.sol";

/// @notice Sepolia-specific hook address mining utility
/// @dev Generates valid hook addresses for Sepolia deployment with correct PoolManager
contract SepoliaHookMiner is Script {
    address constant CREATE2_DEPLOYER = address(0x4e59b44847b379578588920cA78FbF26c0B4956C);
    uint256 constant SEPOLIA_CHAIN_ID = 11155111;
    
    function run() external {
        // Get the correct Sepolia PoolManager address
        address sepoliaPoolManager = PoolManagerAddresses.getPoolManagerByChainId(SEPOLIA_CHAIN_ID);
        
        console.log("=== SEPOLIA HOOK MINING ===");
        console.log("Target Chain: Sepolia (11155111)");
        console.log("PoolManager Address:", sepoliaPoolManager);
        console.log("Deployer Address:", msg.sender);
        console.log("");

        // Define the permissions our StealthAuction hook needs
        Hooks.Permissions memory permissions = Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: true,      // Setup FHE infrastructure
            beforeAddLiquidity: true,   // Coordinate with auctions
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,          // Validate against encrypted limits
            afterSwap: true,           // Update encrypted state
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });

        // Calculate the required flags from permissions
        uint160 flags = uint160(
            Hooks.AFTER_INITIALIZE_FLAG |
            Hooks.BEFORE_ADD_LIQUIDITY_FLAG |
            Hooks.BEFORE_SWAP_FLAG |
            Hooks.AFTER_SWAP_FLAG
        );

        console.log("Hook Permissions Required:");
        console.log("- afterInitialize:", permissions.afterInitialize);
        console.log("- beforeAddLiquidity:", permissions.beforeAddLiquidity);
        console.log("- beforeSwap:", permissions.beforeSwap);
        console.log("- afterSwap:", permissions.afterSwap);
        console.log("Required flags (decimal):", flags);
        console.log("Required flags (hex):", vm.toString(abi.encodePacked(flags)));
        console.log("");

        // Mine for a valid salt
        console.log("Starting salt mining process...");
        (address hookAddress, bytes32 salt) = mineSalt(flags, sepoliaPoolManager);
        
        console.log("");
        console.log("=== MINING RESULTS ===");
        console.log("Valid Hook Address:", hookAddress);
        console.log("Salt (bytes32):", vm.toString(salt));
        console.log("Salt (uint256):", uint256(salt));
        console.log("Salt (hex):", vm.toString(abi.encodePacked(salt)));
        
        // Verify the address is valid
        require(uint160(hookAddress) & (~flags) == uint160(0), "Invalid hook address generated");
        console.log("[SUCCESS] Address validation passed!");
        
        // Generate deployment command
        console.log("");
        console.log("=== DEPLOYMENT COMMAND ===");
        console.log("forge script script/SepoliaDeployment.s.sol \\");
        console.log("  --rpc-url $RPC_URL \\");
        console.log("  --private-key $PRIVATE_KEY \\");
        console.log("  --broadcast \\");
        console.log("  --verify \\");
        console.log("  --etherscan-api-key $ETHERSCAN_API_KEY \\");
        console.log("  --sig \"run(bytes32)\" \\");
        console.log("  ", vm.toString(salt));
    }

    function mineSalt(uint160 flags, address poolManager) internal returns (address, bytes32) {
        // Generate bytecode with correct PoolManager address
        bytes memory bytecode = abi.encodePacked(
            vm.getCode("StealthAuction.sol:StealthAuction"),
            abi.encode(poolManager)
        );
        
        bytes32 bytecodeHash = keccak256(bytecode);
        console.log("Bytecode Hash:", vm.toString(bytecodeHash));
        
        uint256 attempts = 0;
        uint256 maxAttempts = 1000000; // Limit attempts to avoid infinite loop
        
        // Mine for a valid salt
        for (uint256 i = 0; i < maxAttempts; i++) {
            bytes32 salt = bytes32(i);
            attempts++;
            
            address predicted = computeAddress(salt, bytecodeHash, msg.sender);
            
            // Check if this address satisfies our hook requirements
            if (uint160(predicted) & (~flags) == uint160(0)) {
                console.log("Found valid address after", attempts, "attempts");
                return (predicted, salt);
            }
            
            // Log progress every 50k iterations
            if (i % 50000 == 0 && i > 0) {
                console.log("Checked", i, "salts...");
            }
        }
        
        revert("Could not find valid salt within attempt limit");
    }

    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) 
        internal 
        pure 
        returns (address) 
    {
        return address(uint160(uint256(keccak256(abi.encodePacked(
            bytes1(0xff),
            deployer,
            salt,
            bytecodeHash
        )))));
    }

    // Utility function to verify an existing salt
    function verifySalt(bytes32 salt, address expectedHook) external view returns (bool) {
        address poolManager = PoolManagerAddresses.getPoolManagerByChainId(SEPOLIA_CHAIN_ID);
        
        bytes memory bytecode = abi.encodePacked(
            vm.getCode("StealthAuction.sol:StealthAuction"),
            abi.encode(poolManager)
        );
        
        address computed = computeAddress(salt, keccak256(bytecode), msg.sender);
        return computed == expectedHook;
    }
}
