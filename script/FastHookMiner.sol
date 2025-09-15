// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";

/// @notice Fast hook address miner with batch processing
/// @dev More efficient than the previous implementation
contract FastHookMiner is Script {
    address constant SEPOLIA_POOL_MANAGER = 0xE03A1074c86CFeDd5C142C4F04F1a1536e203543;
    uint160 constant REQUIRED_FLAGS = 0x18C0; // 6336 decimal
    
    struct MiningResult {
        address hookAddress;
        bytes32 salt;
        uint256 attempts;
        bool found;
    }
    
    function run() external returns (MiningResult memory result) {
        console.log("=== FAST HOOK MINING FOR SEPOLIA ===");
        console.log("Target flags: 0x18C0 (6336)");
        console.log("Pool Manager:", SEPOLIA_POOL_MANAGER);
        console.log("Deployer:", msg.sender);
        console.log("");
        
        // Generate deployment bytecode
        bytes memory bytecode = abi.encodePacked(
            vm.getCode("StealthAuction.sol:StealthAuction"),
            abi.encode(SEPOLIA_POOL_MANAGER)
        );
        bytes32 bytecodeHash = keccak256(bytecode);
        
        console.log("Bytecode hash:", vm.toString(bytecodeHash));
        console.log("Starting mining...");
        
        // Mine with optimized batch processing
        result = mineBatch(bytecodeHash, 1000000); // 1M attempts max
        
        if (result.found) {
            console.log("");
            console.log("[SUCCESS] Valid hook address found:");
            console.log("Address:", result.hookAddress);
            console.log("Salt:", vm.toString(result.salt));
            console.log("Attempts:", result.attempts);
            console.log("");
            console.log("Deploy command:");
            console.log("forge script script/SepoliaDeployment.s.sol \\");
            console.log("  --fork-url $RPC_URL \\");
            console.log("  --private-key $PRIVATE_KEY \\");
            console.log("  --broadcast \\");
            console.log("  --verify \\");
            console.log("  --sig \"run(bytes32)\" \\");
            console.log(" ", vm.toString(result.salt));
        } else {
            console.log("");
            console.log("[FAILED] No valid address found in", result.attempts, "attempts");
            console.log("Try running again or increase batch size");
        }
        
        return result;
    }
    
    function mineBatch(bytes32 bytecodeHash, uint256 maxAttempts) 
        internal 
        view 
        returns (MiningResult memory result) 
    {
        uint256 startTime = block.timestamp;
        
        for (uint256 i = 0; i < maxAttempts; i++) {
            bytes32 salt = bytes32(i);
            address predicted = mineCreate2Address(salt, bytecodeHash, msg.sender);
            
            // Check if address satisfies hook requirements
            if (uint160(predicted) & (~REQUIRED_FLAGS) == 0) {
                result.hookAddress = predicted;
                result.salt = salt;
                result.attempts = i + 1;
                result.found = true;
                return result;
            }
            
            // Progress updates every 50k attempts
            if (i > 0 && i % 50000 == 0) {
                console.log("Checked", i, "salts...");
            }
        }
        
        result.attempts = maxAttempts;
        result.found = false;
    }
    
    function mineCreate2Address(bytes32 salt, bytes32 bytecodeHash, address deployer) 
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
    
    // Utility function to verify a salt
    function verifySalt(bytes32 salt) external view returns (bool valid, address predicted) {
        bytes memory bytecode = abi.encodePacked(
            vm.getCode("StealthAuction.sol:StealthAuction"),
            abi.encode(SEPOLIA_POOL_MANAGER)
        );
        
        predicted = mineCreate2Address(salt, keccak256(bytecode), msg.sender);
        valid = uint160(predicted) & (~REQUIRED_FLAGS) == 0;
        
        console.log("Salt:", vm.toString(salt));
        console.log("Predicted address:", predicted);
        console.log("Valid:", valid);
        
        if (valid) {
            console.log("[VALID] This salt will generate a valid hook address!");
        } else {
            console.log("[INVALID] This salt will NOT generate a valid hook address");
        }
    }
}
