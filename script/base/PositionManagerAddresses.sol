//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title PositionManagerAddresses
/// @notice Mapping of chain IDs to PositionManager addresses
library PositionManagerAddresses {
    /// @notice Get PositionManager address for a given chain ID
    /// @param chainId The chain ID to get the PositionManager address for
    /// @return positionManagerAddress The PositionManager address for the given chain ID
    function getPositionManagerByChainId(uint256 chainId) internal pure returns (address positionManagerAddress) {
        if (chainId == 31337) {
            // Anvil
            positionManagerAddress = address(0x0000000000000000000000000000000000000000); // Not deployed for Anvil testing
        } else if (chainId == 11155111) {
            // Ethereum Sepolia
            positionManagerAddress = address(0x1B1C77B606d13b09C84d1c7394B96b147bC03147);
        } else if (chainId == 421614) {
            // Arbitrum Sepolia
            positionManagerAddress = address(0x1B1C77B606d13b09C84d1c7394B96b147bC03147);
        } else if (chainId == 84532) {
            // Base Sepolia
            positionManagerAddress = address(0x4b2c77d209d3405f41a037ec6c77f7f5b8e2ca80);
        } else if (chainId == 8008135) {
            // Fhenix Helium
            positionManagerAddress = address(0x1B1C77B606d13b09C84d1c7394B96b147bC03147);
        } else {
            revert("PositionManagerAddresses: unsupported chain");
        }
    }
}
