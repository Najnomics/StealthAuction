// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {euint128} from "@fhenixprotocol/cofhe-contracts/FHE.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title IFHERC20
/// @notice Interface for FHE-enabled ERC20 tokens
/// @dev Extends standard ERC20 with encrypted balance and transfer operations following template patterns
interface IFHERC20 is IERC20 {
    /// @notice Transfer encrypted amount from one address to another
    /// @param from The sender address
    /// @param to The recipient address
    /// @param encAmount The encrypted amount to transfer
    /// @return success True if transfer succeeded
    function transferFromEncrypted(address from, address to, euint128 encAmount) external returns (bool success);

    /// @notice Transfer encrypted amount to an address
    /// @param to The recipient address
    /// @param encAmount The encrypted amount to transfer
    /// @return success True if transfer succeeded
    function transferEncrypted(address to, euint128 encAmount) external returns (bool success);

    /// @notice Mint encrypted tokens to an address
    /// @param to The recipient address
    /// @param encAmount The encrypted amount to mint
    function mintEncrypted(address to, euint128 encAmount) external;

    /// @notice Burn encrypted tokens from an address
    /// @param from The address to burn from
    /// @param encAmount The encrypted amount to burn
    function burnEncrypted(address from, euint128 encAmount) external;

    /// @notice Get encrypted balance of an address
    /// @param account The account to query
    /// @return The encrypted balance
    function balanceOfEncrypted(address account) external view returns (euint128);

    /// @notice Approve encrypted spending amount
    /// @param spender The spender address
    /// @param encAmount The encrypted amount to approve
    /// @return success True if approval succeeded
    function approveEncrypted(address spender, euint128 encAmount) external returns (bool success);

    /// @notice Get encrypted allowance
    /// @param owner The owner address
    /// @param spender The spender address
    /// @return The encrypted allowance
    function allowanceEncrypted(address owner, address spender) external view returns (euint128);

    /// @notice Initialize the token (for upgradeable tokens)
    /// @param name The token name
    /// @param symbol The token symbol
    function initialize(string memory name, string memory symbol) external;

    /// @notice Events for encrypted operations
    event EncryptedTransfer(address indexed from, address indexed to, bytes32 encryptedAmount);
    event EncryptedApproval(address indexed owner, address indexed spender, bytes32 encryptedAmount);
    event EncryptedMint(address indexed to, bytes32 encryptedAmount);
    event EncryptedBurn(address indexed from, bytes32 encryptedAmount);
}
