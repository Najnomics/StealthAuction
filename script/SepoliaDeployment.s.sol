// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import {StealthAuction} from "../src/StealthAuction.sol";
import {StealthAuctionToken} from "../src/StealthAuctionToken.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolManagerAddresses} from "./base/PoolManagerAddresses.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";

/// @notice Sepolia deployment script with proper hook address mining
/// @dev Deploys StealthAuction hook and supporting contracts to Sepolia
contract SepoliaDeployment is Script {
    uint256 constant SEPOLIA_CHAIN_ID = 11155111;
    
    struct DeploymentResult {
        address stealthAuctionHook;
        address auctionToken;
        address baseToken;
        address poolManager;
        string network;
    }
    
    event SepoliaDeploymentComplete(
        address indexed hook,
        address indexed poolManager,
        address auctionToken,
        address baseToken
    );
    
    function run() external {
        // Default salt (will be overridden if provided)
        bytes32 salt = bytes32(0);
        run(salt);
    }
    
    function run(bytes32 salt) public {
        require(block.chainid == SEPOLIA_CHAIN_ID, "Must deploy on Sepolia");
        
        console.log("=== SEPOLIA DEPLOYMENT STARTING ===");
        console.log("Chain ID:", block.chainid);
        console.log("Deployer:", msg.sender);
        console.log("Salt:", vm.toString(salt));
        console.log("");
        
        vm.startBroadcast();
        
        DeploymentResult memory result = deployComplete(salt);
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=== DEPLOYMENT COMPLETE ===");
        console.log("Network:", result.network);
        console.log("PoolManager:", result.poolManager);
        console.log("StealthAuction Hook:", result.stealthAuctionHook);
        console.log("Auction Token:", result.auctionToken);
        console.log("Base Token:", result.baseToken);
        
        // Verify hook address is valid
        verifyHookAddress(result.stealthAuctionHook);
        
        emit SepoliaDeploymentComplete(
            result.stealthAuctionHook,
            result.poolManager,
            result.auctionToken,
            result.baseToken
        );
        
        console.log("");
        console.log("=== NEXT STEPS ===");
        console.log("1. Verify contracts on Etherscan");
        console.log("2. Update frontend configuration with new addresses");
        console.log("3. Test hook functionality with sample auction");
    }
    
    function deployComplete(bytes32 salt) internal returns (DeploymentResult memory result) {
        // Get Sepolia PoolManager address
        result.poolManager = PoolManagerAddresses.getPoolManagerByChainId(SEPOLIA_CHAIN_ID);
        result.network = "Sepolia Testnet";
        
        console.log("Using PoolManager:", result.poolManager);
        
        // Deploy hook with mined address
        result.stealthAuctionHook = deployStealthAuctionHook(result.poolManager, salt);
        
        // Deploy supporting tokens
        (result.auctionToken, result.baseToken) = deployTokens();
        
        console.log("");
        console.log("All contracts deployed successfully!");
        
        return result;
    }
    
    function deployStealthAuctionHook(address poolManager, bytes32 salt) 
        internal 
        returns (address hookAddress) 
    {
        console.log("Deploying StealthAuction hook...");
        
        // Create deployment bytecode
        bytes memory bytecode = abi.encodePacked(
            type(StealthAuction).creationCode,
            abi.encode(poolManager)
        );
        
        // Deploy using CREATE2 with provided salt
        assembly {
            hookAddress := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        
        require(hookAddress != address(0), "Hook deployment failed");
        
        console.log("StealthAuction deployed at:", hookAddress);
        
        // Verify the deployment worked correctly
        StealthAuction hook = StealthAuction(hookAddress);
        require(address(hook.poolManager()) == poolManager, "Hook PoolManager mismatch");
        
        console.log("Hook deployment verified successfully");
        
        return hookAddress;
    }
    
    function deployTokens() internal returns (address auctionToken, address baseToken) {
        console.log("Deploying test tokens...");
        
        // Deploy auction token
        auctionToken = address(new StealthAuctionToken(
            "Stealth Auction Token",
            "SAT"
        ));
        
        // Deploy base token
        baseToken = address(new StealthAuctionToken(
            "Base Test Token", 
            "BTT"
        ));
        
        console.log("Auction Token deployed at:", auctionToken);
        console.log("Base Token deployed at:", baseToken);
        
        return (auctionToken, baseToken);
    }
    
    function verifyHookAddress(address hookAddress) internal view {
        console.log("Verifying hook address validity...");
        
        // Check hook permissions match requirements
        uint160 flags = uint160(
            Hooks.AFTER_INITIALIZE_FLAG |
            Hooks.BEFORE_ADD_LIQUIDITY_FLAG |
            Hooks.BEFORE_SWAP_FLAG |
            Hooks.AFTER_SWAP_FLAG
        );
        
        require(
            uint160(hookAddress) & (~flags) == uint160(0),
            "Hook address does not match required permissions"
        );
        
        console.log("[SUCCESS] Hook address validation passed");
        console.log("Hook permissions flags verified:", flags);
    }
    
    // Utility function for testing deployment
    function previewDeployment(bytes32 salt) external view returns (address predictedHook) {
        address poolManager = PoolManagerAddresses.getPoolManagerByChainId(SEPOLIA_CHAIN_ID);
        
        bytes32 bytecodeHash = keccak256(abi.encodePacked(
            type(StealthAuction).creationCode,
            abi.encode(poolManager)
        ));
        
        predictedHook = address(uint160(uint256(keccak256(abi.encodePacked(
            bytes1(0xff),
            msg.sender,
            salt,
            bytecodeHash
        )))));
        
        console.log("Predicted hook address:", predictedHook);
        return predictedHook;
    }
}
