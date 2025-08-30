// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title AuctionToken
/// @notice ERC20 token for testing auction functionality
/// @dev Simple mintable ERC20 for use in auction testing and demonstrations
contract AuctionToken is ERC20, Ownable {
    uint8 private _decimals;

    /// @notice Events
    event TokenMinted(address indexed to, uint256 amount);
    event TokenBurned(address indexed from, uint256 amount);

    /// @notice Constructor
    /// @param name Token name
    /// @param symbol Token symbol
    /// @param decimals_ Token decimals
    constructor(string memory name, string memory symbol, uint8 decimals_) ERC20(name, symbol) Ownable(msg.sender) {
        _decimals = decimals_;
    }

    /// @notice Mint tokens to a specific address
    /// @param to Address to mint tokens to
    /// @param amount Amount of tokens to mint
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
        emit TokenMinted(to, amount);
    }

    /// @notice Burn tokens from a specific address
    /// @param from Address to burn tokens from
    /// @param amount Amount of tokens to burn
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
        emit TokenBurned(from, amount);
    }

    /// @notice Get token decimals
    /// @return Number of decimals
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /// @notice Allow users to burn their own tokens
    /// @param amount Amount of tokens to burn
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
        emit TokenBurned(msg.sender, amount);
    }

    /// @notice Batch mint to multiple addresses
    /// @param recipients Array of recipient addresses
    /// @param amounts Array of amounts to mint
    function batchMint(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        require(recipients.length == amounts.length, "AuctionToken: Arrays length mismatch");

        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], amounts[i]);
            emit TokenMinted(recipients[i], amounts[i]);
        }
    }
}
