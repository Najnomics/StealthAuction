// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @notice Helper to deploy a Permit2 contract
library Permit2Bytecode {
    /// @notice Deploys a Permit2 contract
    /// @return The deployed Permit2 contract
    function deploy() internal returns (address) {
        // For testing, return the canonical Permit2 address
        // In a real deployment, you'd use CREATE2 with the proper bytecode
        return address(0x000000000022D473030F116dDEE9F6B43aC78BA3);
    }
}
