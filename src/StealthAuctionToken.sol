// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IFHERC20} from "./interface/IFHERC20.sol";
import {FHE, InEuint128, euint128} from "@fhenixprotocol/cofhe-contracts/FHE.sol";

/**
 * @title StealthAuctionToken
 * @notice FHE-enabled ERC20 token for stealth auctions with hybrid public/encrypted balances
 * @dev Based on HybridFHERC20 pattern from FHE hook template
 * 
 * Key Features:
 * - Dual balance system: public ERC20 + encrypted FHE balances
 * - Encrypted transfers for auction privacy
 * - Wrap/unwrap functionality between public and encrypted balances
 * - Auction-specific batch operations
 */
contract StealthAuctionToken is ERC20, Ownable, IFHERC20 {
    // ===============================================
    //                   ERRORS
    // ===============================================
    error StealthAuctionToken__InvalidSender();
    error StealthAuctionToken__InvalidReceiver();
    error StealthAuctionToken__InsufficientBalance();

    // ===============================================
    //                   LIBRARIES
    // ===============================================
    using FHE for uint256;

    // ===============================================
    //                   STORAGE
    // ===============================================
    
    /// @notice Encrypted balances mapping
    mapping(address => euint128) public encBalances;
    
    /// @notice Total encrypted supply
    euint128 public totalEncryptedSupply = FHE.asEuint128(0);
    
    /// @notice Zero constant for FHE operations
    euint128 private immutable ZERO = FHE.asEuint128(0);

    // ===============================================
    //                   EVENTS
    // ===============================================
    event EncryptedMint(address indexed to, bytes32 indexed encryptedAmount);
    event EncryptedBurn(address indexed from, bytes32 indexed encryptedAmount);
    event EncryptedTransfer(address indexed from, address indexed to, bytes32 indexed encryptedAmount);
    event BalanceWrapped(address indexed user, uint256 publicAmount, bytes32 encryptedAmount);
    event BalanceUnwrapped(address indexed user, bytes32 encryptedAmount, uint256 publicAmount);
    event EncryptedTransfer(address indexed from, address indexed to);
    event Wrapped(address indexed user, uint256 amount);
    event UnwrapRequested(address indexed user, uint256 indexed requestId);

    // ===============================================
    //                 CONSTRUCTOR
    // ===============================================
    constructor(string memory name, string memory symbol) 
        ERC20(name, symbol) 
        Ownable(msg.sender) 
    {
        FHE.allowThis(ZERO);
        FHE.allowThis(totalEncryptedSupply);
    }

    // ===============================================
    //              PUBLIC MINT/BURN
    // ===============================================
    
    /// @notice Mint public tokens (for testing/setup)
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /// @notice Burn public tokens
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }

    // ===============================================
    //             ENCRYPTED MINT FUNCTIONS
    // ===============================================
    
    function mintEncrypted(address user, InEuint128 memory amount) external onlyOwner {
        _mintEnc(user, FHE.asEuint128(amount));
    }

    function mintEncrypted(address user, euint128 amount) external onlyOwner {
        _mintEnc(user, amount);
    }

    function _mintEnc(address user, euint128 amount) internal {
        encBalances[user] = encBalances[user].add(amount);
        totalEncryptedSupply = totalEncryptedSupply.add(amount);

        // Grant permissions
        FHE.allowThis(encBalances[user]);
        FHE.allow(encBalances[user], user);
        FHE.allowThis(totalEncryptedSupply);
        FHE.allowGlobal(totalEncryptedSupply);

        emit EncryptedMint(user, bytes32(euint128.unwrap(amount)));
    }

    // ===============================================
    //             ENCRYPTED BURN FUNCTIONS
    // ===============================================
    
    function burnEncrypted(address user, InEuint128 memory amount) external onlyOwner {
        _burnEnc(user, FHE.asEuint128(amount));
    }

    function burnEncrypted(address user, euint128 amount) external onlyOwner {
        _burnEnc(user, amount);
    }

    function _burnEnc(address user, euint128 amount) internal {
        euint128 burnAmount = _calculateBurnAmount(user, amount);
        encBalances[user] = encBalances[user].sub(burnAmount);
        totalEncryptedSupply = totalEncryptedSupply.sub(burnAmount);

        // Grant permissions
        FHE.allowThis(encBalances[user]);
        FHE.allow(encBalances[user], user);
        FHE.allowThis(totalEncryptedSupply);
        FHE.allowGlobal(totalEncryptedSupply);

        emit EncryptedBurn(user, bytes32(euint128.unwrap(amount)));
    }

    function _calculateBurnAmount(address user, euint128 amount) internal returns (euint128) {
        return FHE.select(amount.lte(encBalances[user]), amount, ZERO);
    }

    // ===============================================
    //           ENCRYPTED TRANSFER FUNCTIONS
    // ===============================================
    
    function transferEncrypted(address to, InEuint128 memory amount) external returns (euint128) {
        return _transferImpl(msg.sender, to, FHE.asEuint128(amount));
    }

    function transferEncrypted(address to, euint128 amount) external returns (euint128) {
        return _transferImpl(msg.sender, to, amount);
    }

    function transferFromEncrypted(address from, address to, InEuint128 memory amount) external returns (euint128) {
        return _transferImpl(from, to, FHE.asEuint128(amount));
    }

    function transferFromEncrypted(address from, address to, euint128 amount) external returns (euint128) {
        return _transferImpl(from, to, amount);
    }

    function _transferImpl(address from, address to, euint128 amount) internal returns (euint128) {
        // Validate addresses
        if (from == address(0)) {
            revert StealthAuctionToken__InvalidSender();
        }
        if (to == address(0)) {
            revert StealthAuctionToken__InvalidReceiver();
        }

        // Check allowance for transferFrom (not needed if sender is transferring their own tokens)
        if (msg.sender != from) {
            _spendAllowance(from, msg.sender, uint256(euint128.unwrap(amount)));
        }

        // Calculate amount to transfer (limited by sender's balance)
        euint128 amountToSend = FHE.select(amount.lte(encBalances[from]), amount, ZERO);

        // Update balances
        encBalances[to] = encBalances[to].add(amountToSend);
        encBalances[from] = encBalances[from].sub(amountToSend);

        // Grant permissions
        FHE.allowThis(encBalances[to]);
        FHE.allowThis(encBalances[from]);
        FHE.allow(encBalances[to], to);
        FHE.allow(encBalances[from], from);

        emit EncryptedTransfer(from, to);
        return amountToSend;
    }

    // ===============================================
    //            DECRYPT BALANCE FUNCTIONS
    // ===============================================
    
    function decryptBalance(address user) external {
        FHE.decrypt(encBalances[user]);
    }

    function getDecryptBalanceResult(address user) external view returns (uint128) {
        return FHE.getDecryptResult(encBalances[user]);
    }

    function getDecryptBalanceResultSafe(address user) external view returns (uint128, bool) {
        return FHE.getDecryptResultSafe(encBalances[user]);
    }

    // ===============================================
    //           ENCRYPTED WRAPPING FUNCTIONS
    // ===============================================
    
    function wrap(address user, uint128 amount) external {
        _wrap(user, amount);
    }

    function _wrap(address user, uint128 amount) internal {
        // Burn public balance
        _burn(user, uint256(amount));

        // Mint encrypted balance
        _mintEnc(user, FHE.asEuint128(amount));

        emit Wrapped(user, amount);
    }

    // ===============================================
    //          ENCRYPTED UNWRAPPING FUNCTIONS
    // ===============================================
    
    function requestUnwrap(address user, InEuint128 memory amount) external returns (euint128) {
        return _requestUnwrap(user, FHE.asEuint128(amount));
    }

    function requestUnwrap(address user, euint128 amount) external returns (euint128) {
        return _requestUnwrap(user, amount);
    }

    function _requestUnwrap(address user, euint128 amount) internal returns (euint128 burnAmount) {
        burnAmount = _calculateBurnAmount(user, amount);
        // Request decryption of burn amount
        FHE.decrypt(burnAmount);
        emit UnwrapRequested(user, euint128.unwrap(burnAmount));
    }

    function getUnwrapResult(address user, euint128 burnAmount) external returns (uint128 amount) {
        return _getUnwrapResult(user, burnAmount);
    }

    function getUnwrapResultSafe(address user, euint128 burnAmount) external returns (uint128 amount, bool decrypted) {
        return _getUnwrapResultSafe(user, burnAmount);
    }

    function _getUnwrapResult(address user, euint128 burnAmount) internal returns (uint128 amount) {
        amount = FHE.getDecryptResult(burnAmount);

        // Burn encrypted balance
        _burnEnc(user, burnAmount);

        // Mint public balance
        _mint(user, amount);
    }

    function _getUnwrapResultSafe(address user, euint128 burnAmount) internal returns (uint128 amount, bool decrypted) {
        (amount, decrypted) = FHE.getDecryptResultSafe(burnAmount);

        if (!decrypted) {
            return (0, false);
        }

        // Burn encrypted balance
        _burnEnc(user, burnAmount);

        // Mint public balance
        _mint(user, amount);
    }

    // ===============================================
    //               AUCTION-SPECIFIC FUNCTIONS
    // ===============================================
    
    /// @notice Batch mint encrypted tokens for multiple auction participants
    /// @param recipients Array of recipient addresses
    /// @param amounts Array of encrypted amounts to mint
    function batchMintEncrypted(address[] calldata recipients, euint128[] calldata amounts) 
        external 
        onlyOwner 
    {
        require(recipients.length == amounts.length, "Array length mismatch");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            _mintEnc(recipients[i], amounts[i]);
        }
    }

    /// @notice Initialize auction token supply with encrypted amount
    /// @param auctionContract Address of the auction contract
    /// @param encryptedSupply Encrypted total supply for the auction
    function initializeAuctionSupply(address auctionContract, euint128 encryptedSupply) 
        external 
        onlyOwner 
    {
        _mintEnc(auctionContract, encryptedSupply);
        
        // Grant auction contract permission to manage this supply
        FHE.allow(encryptedSupply, auctionContract);
    }

    /// @notice Initialize auction token supply with encrypted amount (InEuint128 overload)
    /// @param auctionContract Address of the auction contract
    /// @param amount Encrypted input amount for the auction
    function initializeAuctionSupply(address auctionContract, InEuint128 memory amount) 
        external 
        onlyOwner 
    {
        euint128 encryptedSupply = FHE.asEuint128(amount);
        _mintEnc(auctionContract, encryptedSupply);
        
        // Grant auction contract permission to manage this supply
        FHE.allow(encryptedSupply, auctionContract);
    }
}
