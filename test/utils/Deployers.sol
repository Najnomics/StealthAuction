// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {Deployers as V4Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolManager} from "@uniswap/v4-core/src/PoolManager.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {LPFeeLibrary} from "@uniswap/v4-core/src/libraries/LPFeeLibrary.sol";
import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";

// FHE Imports
import {FHE, euint128, euint64} from "@fhenixprotocol/cofhe-contracts/FHE.sol";

/// @title Test Deployers
/// @notice Comprehensive deployment utilities for Uniswap v4 + FHE testing
/// @dev Extends v4-core Deployers with FHE-compatible token support and position management
contract Deployers is Test, V4Deployers {
    using PoolIdLibrary for PoolKey;
    using LPFeeLibrary for uint24;

    // Core Uniswap v4 contracts
    IPoolManager public manager;

    // Test tokens
    MockERC20 public token0;
    MockERC20 public token1;
    Currency public currency0;
    Currency public currency1;

    // FHE-compatible tokens (using MockERC20 for now)
    MockERC20 public fheToken0;
    MockERC20 public fheToken1;
    Currency public fheCurrency0;
    Currency public fheCurrency1;

    // Standard test pool configuration
    PoolKey public key;
    PoolKey public fheKey;
    PoolId public poolId;
    PoolId public fhePoolId;

    // Test constants
    uint160 public constant SQRT_PRICE_1_1 = Constants.SQRT_PRICE_1_1;
    int24 public constant TICK_SPACING = 60;
    uint24 public constant LP_FEE = 3000;

    function setUp() public virtual {
        // Deploy core v4 infrastructure
        deployFreshManagerAndRouters();
        
        // Deploy tokens
        deployTokens();
        deployFHETokens();
        
        // Initialize test pools
        initializeTestPools();
    }

    /// @notice Deploy standard ERC20 tokens for testing
    function deployTokens() public {
        token0 = new MockERC20("Token0", "T0", 18);
        token1 = new MockERC20("Token1", "T1", 18);

        // Ensure token0 < token1 for Uniswap v4
        if (address(token0) > address(token1)) {
            (token0, token1) = (token1, token0);
        }

        currency0 = Currency.wrap(address(token0));
        currency1 = Currency.wrap(address(token1));

        // Mint large amounts for testing
        token0.mint(address(this), 1000000 ether);
        token1.mint(address(this), 1000000 ether);

        // Approve for pool manager
        token0.approve(address(manager), type(uint256).max);
        token1.approve(address(manager), type(uint256).max);
    }

    /// @notice Deploy FHE-compatible tokens using template patterns
    function deployFHETokens() public {
        // For now, use MockERC20 tokens with FHE-like names
        // In production, these would be proper FHE tokens
        fheToken0 = new MockERC20("FHE Token 0", "FHET0", 18);
        fheToken1 = new MockERC20("FHE Token 1", "FHET1", 18);

        // Ensure FHE token0 < token1
        if (address(fheToken0) > address(fheToken1)) {
            (fheToken0, fheToken1) = (fheToken1, fheToken0);
        }

        fheCurrency0 = Currency.wrap(address(fheToken0));
        fheCurrency1 = Currency.wrap(address(fheToken1));

        // Mint test amounts
        fheToken0.mint(address(this), 1000000 ether);
        fheToken1.mint(address(this), 1000000 ether);

        // Approve for managers
        fheToken0.approve(address(manager), type(uint256).max);
        fheToken1.approve(address(manager), type(uint256).max);
    }

    /// @notice Initialize standard test pools
    function initializeTestPools() public {
        // Standard ERC20 pool
        key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: LP_FEE.isDynamicFee() ? LPFeeLibrary.DYNAMIC_FEE_FLAG : LP_FEE,
            tickSpacing: TICK_SPACING,
            hooks: IHooks(address(0))
        });

        poolId = key.toId();
        manager.initialize(key, SQRT_PRICE_1_1, "");

        // FHE token pool
        fheKey = PoolKey({
            currency0: fheCurrency0,
            currency1: fheCurrency1,
            fee: LP_FEE.isDynamicFee() ? LPFeeLibrary.DYNAMIC_FEE_FLAG : LP_FEE,
            tickSpacing: TICK_SPACING,
            hooks: IHooks(address(0))
        });

        fhePoolId = fheKey.toId();
        manager.initialize(fheKey, SQRT_PRICE_1_1, "");
    }

    /// @notice Deploy a hook with mining (template pattern)
    /// @param hookAddress The target hook address (must have correct permissions)
    /// @param hookCode The hook contract bytecode
    /// @return The deployed hook contract
    function deployHookWithMining(address hookAddress, bytes memory hookCode) public returns (IHooks) {
        // Verify hook address has correct permissions
        uint160 permissions = uint160(hookAddress) & Hooks.ALL_HOOK_MASK;
        require(permissions != 0, "Hook address has no permissions");

        // Deploy using vm.etch (template pattern)
        vm.etch(hookAddress, hookCode);
        
        return IHooks(hookAddress);
    }

    /// @notice Create a pool key with a specific hook
    /// @param _currency0 First currency
    /// @param _currency1 Second currency
    /// @param _hooks Hook contract address
    /// @return The pool key
    function createPoolKey(Currency _currency0, Currency _currency1, IHooks _hooks) public pure returns (PoolKey memory) {
        return PoolKey({
            currency0: _currency0,
            currency1: _currency1,
            fee: LP_FEE.isDynamicFee() ? LPFeeLibrary.DYNAMIC_FEE_FLAG : LP_FEE,
            tickSpacing: TICK_SPACING,
            hooks: _hooks
        });
    }

    /// @notice Create and initialize a pool with hook
    /// @param _key The pool key
    /// @param sqrtPriceX96 Initial price
    /// @param hookData Hook initialization data
    /// @return The pool ID
    function createAndInitializePool(PoolKey memory _key, uint160 sqrtPriceX96, bytes memory hookData) public returns (PoolId) {
        PoolId id = _key.toId();
        manager.initialize(_key, sqrtPriceX96, hookData);
        return id;
    }

    /// @notice Helper to approve tokens for an address
    /// @param spender The address to approve
    function approveTokensFor(address spender) public {
        token0.approve(spender, type(uint256).max);
        token1.approve(spender, type(uint256).max);
        fheToken0.approve(spender, type(uint256).max);
        fheToken1.approve(spender, type(uint256).max);
    }

    /// @notice Helper to mint tokens to an address
    /// @param to The recipient address
    /// @param amount The amount to mint
    function mintTokensTo(address to, uint256 amount) public {
        token0.mint(to, amount);
        token1.mint(to, amount);
        fheToken0.mint(to, amount);
        fheToken1.mint(to, amount);
    }

    /// @notice Get the hook permissions for an address
    /// @param hookAddress The hook address
    /// @return The permissions bitmap
    function getHookPermissions(address hookAddress) public pure returns (uint160) {
        return uint160(hookAddress) & Hooks.ALL_HOOK_MASK;
    }

    /// @notice Helper to get a valid hook address with specific permissions
    /// @param permissions The desired permissions bitmap
    /// @return A valid hook address
    function getHookAddress(uint160 permissions) public pure returns (address) {
        return address(permissions | 0x1000000000000000000000000000000000000000);
    }

    /// @notice Deploy mock contracts for testing
    function deployMocks() public {
        // Deploy any additional mock contracts needed for testing
        // This can be extended as needed
    }

    /// @notice Clean up test state
    function tearDown() public virtual {
        // Reset any global state if needed
        delete token0;
        delete token1;
        delete fheToken0;
        delete fheToken1;
    }
}
