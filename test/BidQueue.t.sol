// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {BidQueue} from "../src/lib/BidQueue.sol";
import {FHE, euint128} from "@fhenixprotocol/cofhe-contracts/FHE.sol";
import {CoFheTest} from "@fhenixprotocol/cofhe-mock-contracts/CoFheTest.sol";

/// @title BidQueue Test Suite
/// @notice Comprehensive tests for encrypted bid queue functionality
contract BidQueueTest is Test, CoFheTest {
    BidQueue private queue;

    function setUp() public {
        queue = new BidQueue();
    }

    modifier queueEmptyStartEnd() {
        assertTrue(queue.isEmpty());
        assertEq(queue.length(), 0);
        _;
        assertTrue(queue.isEmpty());
        assertEq(queue.length(), 0);
    }

    // =============================================================
    //                    BASIC FUNCTIONALITY TESTS
    // =============================================================

    function test_InitialState() public {
        assertTrue(queue.isEmpty());
        assertEq(queue.length(), 0);
    }

    function test_EnqueueSingle() public queueEmptyStartEnd {
        euint128 bid = FHE.asEuint128(10 ether);
        
        vm.expectEmit(true, false, false, false);
        emit BidQueue.BidQueued(bid);
        
        queue.enqueue(bid);

        assertFalse(queue.isEmpty());
        assertEq(queue.length(), 1);
        assertEq(euint128.unwrap(queue.peek()), euint128.unwrap(bid));
        assertHashValue(queue.peek(), 10 ether);

        vm.expectEmit(true, false, false, false);
        emit BidQueue.BidProcessed(bid);
        
        euint128 dequeued = queue.dequeue();
        assertEq(euint128.unwrap(dequeued), euint128.unwrap(bid));
        assertHashValue(dequeued, 10 ether);
    }

    function test_EnqueueMultiple() public {
        euint128 bid1 = FHE.asEuint128(5 ether);
        euint128 bid2 = FHE.asEuint128(8 ether);
        euint128 bid3 = FHE.asEuint128(12 ether);

        queue.enqueue(bid1);
        queue.enqueue(bid2);
        queue.enqueue(bid3);

        assertFalse(queue.isEmpty());
        assertEq(queue.length(), 3);

        // FIFO order - first in, first out
        assertHashValue(queue.peek(), 5 ether);

        euint128 dequeued1 = queue.dequeue();
        assertHashValue(dequeued1, 5 ether);
        assertEq(queue.length(), 2);

        euint128 dequeued2 = queue.dequeue();
        assertHashValue(dequeued2, 8 ether);
        assertEq(queue.length(), 1);

        euint128 dequeued3 = queue.dequeue();
        assertHashValue(dequeued3, 12 ether);
        assertEq(queue.length(), 0);
        assertTrue(queue.isEmpty());
    }

    // =============================================================
    //                    PRIORITY QUEUE TESTS
    // =============================================================

    function test_EnqueuePriority() public {
        euint128 normalBid = FHE.asEuint128(5 ether);
        euint128 priorityBid = FHE.asEuint128(10 ether);

        // Add normal bid first
        queue.enqueue(normalBid);
        assertHashValue(queue.peek(), 5 ether);

        // Add priority bid to front
        queue.enqueuePriority(priorityBid);
        assertEq(queue.length(), 2);

        // Priority bid should be at front now
        assertHashValue(queue.peek(), 10 ether);

        // Dequeue should get priority bid first
        euint128 first = queue.dequeue();
        assertHashValue(first, 10 ether);

        euint128 second = queue.dequeue();
        assertHashValue(second, 5 ether);
    }

    function test_DequeueBack() public {
        euint128 bid1 = FHE.asEuint128(5 ether);
        euint128 bid2 = FHE.asEuint128(8 ether);
        euint128 bid3 = FHE.asEuint128(12 ether);

        queue.enqueue(bid1);
        queue.enqueue(bid2);
        queue.enqueue(bid3);

        // Peek back should show last item
        assertHashValue(queue.peekBack(), 12 ether);

        // Dequeue from back (LIFO style)
        euint128 lastBid = queue.dequeueBack();
        assertHashValue(lastBid, 12 ether);
        assertEq(queue.length(), 2);

        // Remaining items should still be in original order
        assertHashValue(queue.peek(), 5 ether);
    }

    // =============================================================
    //                    QUEUE MANAGEMENT TESTS
    // =============================================================

    function test_Clear() public {
        euint128 bid1 = FHE.asEuint128(5 ether);
        euint128 bid2 = FHE.asEuint128(8 ether);
        euint128 bid3 = FHE.asEuint128(12 ether);

        queue.enqueue(bid1);
        queue.enqueue(bid2);
        queue.enqueue(bid3);

        assertEq(queue.length(), 3);
        assertFalse(queue.isEmpty());

        queue.clear();

        assertEq(queue.length(), 0);
        assertTrue(queue.isEmpty());
    }

    function test_MixedOperations() public {
        euint128 bid1 = FHE.asEuint128(5 ether);
        euint128 bid2 = FHE.asEuint128(8 ether);
        euint128 bid3 = FHE.asEuint128(12 ether);
        euint128 priorityBid = FHE.asEuint128(15 ether);

        // Mix of operations
        queue.enqueue(bid1);
        queue.enqueue(bid2);
        queue.enqueuePriority(priorityBid);
        queue.enqueue(bid3);

        // Should have: priorityBid, bid1, bid2, bid3
        assertEq(queue.length(), 4);
        assertHashValue(queue.peek(), 15 ether);
        assertHashValue(queue.peekBack(), 12 ether);

        // Remove from front and back
        euint128 front = queue.dequeue();
        assertHashValue(front, 15 ether);

        euint128 back = queue.dequeueBack();
        assertHashValue(back, 12 ether);

        assertEq(queue.length(), 2);
        assertHashValue(queue.peek(), 5 ether);
        assertHashValue(queue.peekBack(), 8 ether);
    }

    // =============================================================
    //                    EDGE CASE TESTS
    // =============================================================

    function test_RevertOnEmptyQueueOperations() public {
        assertTrue(queue.isEmpty());

        // These should revert on empty queue
        vm.expectRevert();
        queue.dequeue();

        vm.expectRevert();
        queue.dequeueBack();

        vm.expectRevert();
        queue.peek();

        vm.expectRevert();
        queue.peekBack();
    }

    function test_ZeroBidValue() public queueEmptyStartEnd {
        euint128 zeroBid = FHE.asEuint128(0);
        
        queue.enqueue(zeroBid);
        assertFalse(queue.isEmpty());
        assertEq(queue.length(), 1);
        
        assertHashValue(queue.peek(), 0);
        
        euint128 dequeued = queue.dequeue();
        assertHashValue(dequeued, 0);
    }

    function test_LargeBidValues() public queueEmptyStartEnd {
        euint128 largeBid = FHE.asEuint128(type(uint128).max);
        
        queue.enqueue(largeBid);
        assertHashValue(queue.peek(), type(uint128).max);
        
        euint128 dequeued = queue.dequeue();
        assertHashValue(dequeued, type(uint128).max);
    }

    // =============================================================
    //                    STRESS TESTS
    // =============================================================

    function test_ManyOperations() public {
        uint256 numOperations = 100;
        
        // Fill queue
        for (uint256 i = 0; i < numOperations; i++) {
            euint128 bid = FHE.asEuint128(uint128(i * 1 ether));
            queue.enqueue(bid);
        }
        
        assertEq(queue.length(), numOperations);
        assertFalse(queue.isEmpty());
        
        // Empty queue in FIFO order
        for (uint256 i = 0; i < numOperations; i++) {
            euint128 dequeued = queue.dequeue();
            assertHashValue(dequeued, uint128(i * 1 ether));
        }
        
        assertTrue(queue.isEmpty());
        assertEq(queue.length(), 0);
    }

    // =============================================================
    //                    PROPERTY-BASED TESTS
    // =============================================================

    function testFuzz_EnqueueDequeue(uint128[] memory bidValues) public {
        vm.assume(bidValues.length > 0);
        vm.assume(bidValues.length <= 50); // Reasonable limit for testing

        // Enqueue all bids
        for (uint256 i = 0; i < bidValues.length; i++) {
            euint128 bid = FHE.asEuint128(bidValues[i]);
            queue.enqueue(bid);
        }

        assertEq(queue.length(), bidValues.length);
        
        // Dequeue all bids and verify FIFO order
        for (uint256 i = 0; i < bidValues.length; i++) {
            euint128 dequeued = queue.dequeue();
            assertHashValue(dequeued, bidValues[i]);
        }
        
        assertTrue(queue.isEmpty());
    }

    function testFuzz_MixedOperations(
        uint128 normalBid,
        uint128 priorityBid,
        bool usePriority
    ) public {
        if (usePriority) {
            queue.enqueue(FHE.asEuint128(normalBid));
            queue.enqueuePriority(FHE.asEuint128(priorityBid));
            
            assertEq(queue.length(), 2);
            assertHashValue(queue.peek(), priorityBid);
            
            euint128 first = queue.dequeue();
            assertHashValue(first, priorityBid);
            
            euint128 second = queue.dequeue();
            assertHashValue(second, normalBid);
        } else {
            queue.enqueue(FHE.asEuint128(normalBid));
            queue.enqueue(FHE.asEuint128(priorityBid));
            
            assertEq(queue.length(), 2);
            assertHashValue(queue.peek(), normalBid);
            
            euint128 first = queue.dequeue();
            assertHashValue(first, normalBid);
            
            euint128 second = queue.dequeue();
            assertHashValue(second, priorityBid);
        }
        
        assertTrue(queue.isEmpty());
    }
}
