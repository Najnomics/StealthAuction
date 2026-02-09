// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";

/// @notice Hook address mining utility based on Uniswap v4 docs
/// @dev Generates valid hook addresses that match required permissions
contract HookMiner is Script {
    address constant CREATE2_DEPLOYER = address(0x4e59b44847b379578588920cA78FbF26c0B4956C);

    function run() external {
        // Define the permissions our StealthAuction hook needs
        Hooks.Permissions memory permissions = Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: true, // Coordinate with auctions
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true, // Validate against encrypted limits
            afterSwap: true, // Update encrypted state
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });

        // Calculate the required flags from permissions
        uint160 flags = uint160(Hooks.BEFORE_ADD_LIQUIDITY_FLAG | Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG);

        console.log("Mining hook address with permissions:");
        console.log("afterInitialize:", permissions.afterInitialize);
        console.log("beforeAddLiquidity:", permissions.beforeAddLiquidity);
        console.log("beforeSwap:", permissions.beforeSwap);
        console.log("afterSwap:", permissions.afterSwap);
        console.log("Required flags:", flags);

        // Mine for a valid salt
        (address hookAddress, bytes32 salt) = mineSalt(flags);

        console.log("\n=== HOOK MINING RESULTS ===");
        console.log("Valid hook address:", hookAddress);
        console.log("Salt:", vm.toString(salt));
        console.log("Deployer should be:", msg.sender);

        // Verify the address is valid
        require(uint160(hookAddress) & (~flags) == uint160(0), "Invalid hook address generated");
        console.log("[+] Address validation passed!");

        // Log deployment bytecode hash for verification
        bytes memory bytecode = abi.encodePacked(
            vm.getCode("StealthAuction.sol:StealthAuction"),
            abi.encode(address(0)) // PoolManager placeholder
        );
        console.log("Bytecode hash:", vm.toString(keccak256(bytecode)));
    }

    function mineSalt(uint160 flags) internal view returns (address, bytes32) {
        bytes memory bytecode = abi.encodePacked(
            vm.getCode("StealthAuction.sol:StealthAuction"),
            abi.encode(address(0)) // PoolManager placeholder - will be replaced in actual deployment
        );

        bytes32 bytecodeHash = keccak256(bytecode);

        // Mine for a valid salt (could take a while, but more efficient than our previous approach)
        for (uint256 i = 0; i < type(uint256).max; i++) {
            bytes32 salt = bytes32(i);

            address predicted = computeAddress(salt, bytecodeHash, msg.sender);

            // Check if this address satisfies our hook requirements
            if (uint160(predicted) & (~flags) == uint160(0)) {
                return (predicted, salt);
            }

            // Log progress every 100k iterations
            if (i % 100000 == 0 && i > 0) {
                console.log("Checked", i, "salts...");
            }
        }

        revert("Could not find valid salt");
    }

    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash)))));
    }
}
