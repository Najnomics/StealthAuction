// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {AuctionToken} from "../src/AuctionToken.sol";


/// @title AuctionToken Test Suite
/// @notice Comprehensive tests for auction token functionality
contract AuctionTokenTest is Test {
    AuctionToken token;
    
    address owner = makeAddr("owner");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");

    string constant NAME = "Test Auction Token";
    string constant SYMBOL = "TAT";
    uint8 constant DECIMALS = 18;

    function setUp() public {
        vm.startPrank(owner);
        token = new AuctionToken(NAME, SYMBOL, DECIMALS);
        vm.stopPrank();
    }

    // =============================================================
    //                    BASIC FUNCTIONALITY TESTS
    // =============================================================

    function test_InitialState() public {
        assertEq(token.name(), NAME);
        assertEq(token.symbol(), SYMBOL);
        assertEq(token.decimals(), DECIMALS);
        assertEq(token.totalSupply(), 0);
        assertEq(token.owner(), owner);
    }

    function test_Mint() public {
        uint256 amount = 1000 ether;
        
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit AuctionToken.TokenMinted(user1, amount);
        
        token.mint(user1, amount);
        vm.stopPrank();

        assertEq(token.balanceOf(user1), amount);
        assertEq(token.totalSupply(), amount);
    }

    function test_MintMultiple() public {
        uint256 amount1 = 500 ether;
        uint256 amount2 = 300 ether;
        
        vm.startPrank(owner);
        token.mint(user1, amount1);
        token.mint(user2, amount2);
        vm.stopPrank();

        assertEq(token.balanceOf(user1), amount1);
        assertEq(token.balanceOf(user2), amount2);
        assertEq(token.totalSupply(), amount1 + amount2);
    }

    function test_Burn_ByOwner() public {
        uint256 mintAmount = 1000 ether;
        uint256 burnAmount = 300 ether;
        
        vm.startPrank(owner);
        token.mint(user1, mintAmount);
        
        vm.expectEmit(true, true, false, true);
        emit AuctionToken.TokenBurned(user1, burnAmount);
        
        token.burn(user1, burnAmount);
        vm.stopPrank();

        assertEq(token.balanceOf(user1), mintAmount - burnAmount);
        assertEq(token.totalSupply(), mintAmount - burnAmount);
    }

    function test_Burn_ByUser() public {
        uint256 mintAmount = 1000 ether;
        uint256 burnAmount = 300 ether;
        
        vm.prank(owner);
        token.mint(user1, mintAmount);
        
        vm.startPrank(user1);
        vm.expectEmit(true, true, false, true);
        emit AuctionToken.TokenBurned(user1, burnAmount);
        
        token.burn(burnAmount);
        vm.stopPrank();

        assertEq(token.balanceOf(user1), mintAmount - burnAmount);
        assertEq(token.totalSupply(), mintAmount - burnAmount);
    }

    function test_BatchMint() public {
        address[] memory recipients = new address[](3);
        uint256[] memory amounts = new uint256[](3);
        
        recipients[0] = user1;
        recipients[1] = user2;
        recipients[2] = user3;
        
        amounts[0] = 100 ether;
        amounts[1] = 200 ether;
        amounts[2] = 300 ether;
        
        vm.startPrank(owner);
        
        // Expect events for each mint
        vm.expectEmit(true, true, false, true);
        emit AuctionToken.TokenMinted(user1, 100 ether);
        vm.expectEmit(true, true, false, true);
        emit AuctionToken.TokenMinted(user2, 200 ether);
        vm.expectEmit(true, true, false, true);
        emit AuctionToken.TokenMinted(user3, 300 ether);
        
        token.batchMint(recipients, amounts);
        vm.stopPrank();

        assertEq(token.balanceOf(user1), 100 ether);
        assertEq(token.balanceOf(user2), 200 ether);
        assertEq(token.balanceOf(user3), 300 ether);
        assertEq(token.totalSupply(), 600 ether);
    }

    // =============================================================
    //                    ACCESS CONTROL TESTS
    // =============================================================

    function test_RevertWhen_NonOwnerMints() public {
        vm.startPrank(user1);
        vm.expectRevert();
        token.mint(user2, 100 ether);
        vm.stopPrank();
    }

    function test_RevertWhen_NonOwnerBurns() public {
        vm.prank(owner);
        token.mint(user1, 100 ether);
        
        vm.startPrank(user2);
        vm.expectRevert();
        token.burn(user1, 50 ether);
        vm.stopPrank();
    }

    function test_RevertWhen_NonOwnerBatchMints() public {
        address[] memory recipients = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        recipients[0] = user1;
        amounts[0] = 100 ether;
        
        vm.startPrank(user1);
        vm.expectRevert();
        token.batchMint(recipients, amounts);
        vm.stopPrank();
    }

    // =============================================================
    //                    EDGE CASE TESTS
    // =============================================================

    function test_RevertWhen_BatchMintArrayMismatch() public {
        address[] memory recipients = new address[](2);
        uint256[] memory amounts = new uint256[](3); // Mismatched lengths
        
        recipients[0] = user1;
        recipients[1] = user2;
        amounts[0] = 100 ether;
        amounts[1] = 200 ether;
        amounts[2] = 300 ether;
        
        vm.startPrank(owner);
        vm.expectRevert("AuctionToken: Arrays length mismatch");
        token.batchMint(recipients, amounts);
        vm.stopPrank();
    }

    function test_MintZeroAmount() public {
        vm.startPrank(owner);
        token.mint(user1, 0);
        vm.stopPrank();

        assertEq(token.balanceOf(user1), 0);
        assertEq(token.totalSupply(), 0);
    }

    function test_BurnZeroAmount() public {
        vm.prank(owner);
        token.mint(user1, 100 ether);
        
        vm.startPrank(user1);
        token.burn(0);
        vm.stopPrank();

        assertEq(token.balanceOf(user1), 100 ether);
    }

    function test_RevertWhen_BurnExceedsBalance() public {
        vm.prank(owner);
        token.mint(user1, 100 ether);
        
        vm.startPrank(user1);
        vm.expectRevert();
        token.burn(200 ether); // More than balance
        vm.stopPrank();
    }

    function test_RevertWhen_OwnerBurnExceedsBalance() public {
        vm.prank(owner);
        token.mint(user1, 100 ether);
        
        vm.startPrank(owner);
        vm.expectRevert();
        token.burn(user1, 200 ether); // More than balance
        vm.stopPrank();
    }

    // =============================================================
    //                    TRANSFER FUNCTIONALITY
    // =============================================================

    function test_Transfer() public {
        uint256 amount = 100 ether;
        
        vm.prank(owner);
        token.mint(user1, amount);
        
        vm.startPrank(user1);
        require(token.transfer(user2, 30 ether), "Transfer failed");
        vm.stopPrank();

        assertEq(token.balanceOf(user1), 70 ether);
        assertEq(token.balanceOf(user2), 30 ether);
    }

    function test_Approve_And_TransferFrom() public {
        uint256 amount = 100 ether;
        
        vm.prank(owner);
        token.mint(user1, amount);
        
        vm.startPrank(user1);
        token.approve(user2, 50 ether);
        vm.stopPrank();
        
        assertEq(token.allowance(user1, user2), 50 ether);
        
        vm.startPrank(user2);
        require(token.transferFrom(user1, user3, 30 ether), "TransferFrom failed");
        vm.stopPrank();

        assertEq(token.balanceOf(user1), 70 ether);
        assertEq(token.balanceOf(user3), 30 ether);
        assertEq(token.allowance(user1, user2), 20 ether);
    }

    // =============================================================
    //                    INTEGRATION TESTS
    // =============================================================

    function test_FullLifecycle() public {
        // 1. Mint initial supply
        vm.startPrank(owner);
        token.mint(user1, 1000 ether);
        token.mint(user2, 500 ether);
        vm.stopPrank();
        
        assertEq(token.totalSupply(), 1500 ether);
        
        // 2. Users transfer tokens
        vm.prank(user1);
        require(token.transfer(user3, 100 ether), "Transfer failed");
        
        // 3. Owner burns some tokens
        vm.startPrank(owner);
        token.burn(user2, 100 ether);
        vm.stopPrank();
        
        // 4. User burns their own tokens
        vm.startPrank(user1);
        token.burn(200 ether);
        vm.stopPrank();
        
        // Final state
        assertEq(token.balanceOf(user1), 700 ether);  // 1000 - 100 - 200
        assertEq(token.balanceOf(user2), 400 ether);  // 500 - 100
        assertEq(token.balanceOf(user3), 100 ether);  // Received from user1
        assertEq(token.totalSupply(), 1200 ether);    // 1500 - 100 - 200
    }

    // =============================================================
    //                    PROPERTY-BASED TESTS
    // =============================================================

    function testFuzz_MintAndBurn(uint256 mintAmount, uint256 burnAmount) public {
        mintAmount = bound(mintAmount, 1, type(uint128).max);
        burnAmount = bound(burnAmount, 0, mintAmount);
        
        vm.startPrank(owner);
        token.mint(user1, mintAmount);
        token.burn(user1, burnAmount);
        vm.stopPrank();
        
        assertEq(token.balanceOf(user1), mintAmount - burnAmount);
        assertEq(token.totalSupply(), mintAmount - burnAmount);
    }

    function testFuzz_BatchMint(uint8 numRecipients, uint128 baseAmount) public {
        vm.assume(numRecipients > 0 && numRecipients <= 5); // Reduce to prevent overflow
        vm.assume(baseAmount > 0 && baseAmount <= 1000 ether); // Limit amount to prevent overflow
        
        address[] memory recipients = new address[](numRecipients);
        uint256[] memory amounts = new uint256[](numRecipients);
        uint256 totalExpected = 0;
        
        for (uint8 i = 0; i < numRecipients; i++) {
            recipients[i] = address(uint160(0x1000 + i));
            amounts[i] = baseAmount; // Use same amount to avoid multiplication overflow
            totalExpected += amounts[i];
        }
        
        vm.startPrank(owner);
        token.batchMint(recipients, amounts);
        vm.stopPrank();
        
        assertEq(token.totalSupply(), totalExpected);
        
        for (uint8 i = 0; i < numRecipients; i++) {
            assertEq(token.balanceOf(recipients[i]), amounts[i]);
        }
    }
}
