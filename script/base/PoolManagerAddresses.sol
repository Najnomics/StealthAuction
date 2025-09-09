//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title PoolManagerAddresses
/// @notice Mapping of chain IDs to PoolManager addresses
library PoolManagerAddresses {
    /// @notice Get PoolManager address for a given chain ID
    /// @param chainId The chain ID to get the PoolManager address for
    /// @return poolManagerAddress The PoolManager address for the given chain ID
    function getPoolManagerByChainId(uint256 chainId) internal pure returns (address poolManagerAddress) {
        if (chainId == 31337) {
            // Anvil
            poolManagerAddress = address(0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9);
        } else if (chainId == 11155111) {
            // Ethereum Sepolia
            poolManagerAddress = address(0x0Bf5c45Bc0419229FB512bb00366A612877ffF2D);
        } else if (chainId == 421614) {
            // Arbitrum Sepolia
            poolManagerAddress = address(0x0Bf5c45Bc0419229FB512bb00366A612877ffF2D);
        } else if (chainId == 84532) {
            // Base Sepolia
            poolManagerAddress = address(0x0Bf5c45Bc0419229FB512bb00366A612877ffF2D);
        } else if (chainId == 8008135) {
            // Fhenix Helium
            poolManagerAddress = address(0x0Bf5c45Bc0419229FB512bb00366A612877ffF2D);
        } else {
            revert("PoolManagerAddresses: unsupported chain");
        }
    }
}
