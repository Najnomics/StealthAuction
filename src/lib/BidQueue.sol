// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {euint128} from "@fhenixprotocol/cofhe-contracts/FHE.sol";
import {DoubleEndedQueue} from "@openzeppelin/contracts/utils/structs/DoubleEndedQueue.sol";

/// @title BidQueue
/// @notice Queue for managing encrypted bids in auctions
/// @dev Stores encrypted bid handles in a FIFO queue for fair processing
contract BidQueue {
    using DoubleEndedQueue for DoubleEndedQueue.Bytes32Deque;

    /// @notice Internal queue storage
    DoubleEndedQueue.Bytes32Deque private queue;

    /// @notice Events
    event BidQueued(euint128 indexed bidHandle);
    event BidProcessed(euint128 indexed bidHandle);

    /// @notice Add a bid to the back of the queue
    /// @param bidHandle Encrypted bid handle
    function enqueue(euint128 bidHandle) external {
        queue.pushBack(euintToBytes32(bidHandle));
        emit BidQueued(bidHandle);
    }

    /// @notice Remove and return the bid from the front of the queue
    /// @return bidHandle The encrypted bid handle
    function dequeue() external returns (euint128 bidHandle) {
        bidHandle = bytes32ToEuint(queue.popFront());
        emit BidProcessed(bidHandle);
    }

    /// @notice View the bid at the front of the queue without removing it
    /// @return bidHandle The encrypted bid handle
    function peek() external view returns (euint128 bidHandle) {
        bidHandle = bytes32ToEuint(queue.front());
    }

    /// @notice Get the number of bids in the queue
    /// @return queueLength The queue length
    function length() external view returns (uint256 queueLength) {
        queueLength = queue.length();
    }

    /// @notice Check if the queue is empty
    /// @return queueIsEmpty Whether the queue is empty
    function isEmpty() external view returns (bool queueIsEmpty) {
        queueIsEmpty = queue.empty();
    }

    /// @notice Add a bid to the front of the queue (priority processing)
    /// @param bidHandle Encrypted bid handle
    function enqueuePriority(euint128 bidHandle) external {
        queue.pushFront(euintToBytes32(bidHandle));
        emit BidQueued(bidHandle);
    }

    /// @notice Remove and return the bid from the back of the queue
    /// @return bidHandle The encrypted bid handle
    function dequeueBack() external returns (euint128 bidHandle) {
        bidHandle = bytes32ToEuint(queue.popBack());
        emit BidProcessed(bidHandle);
    }

    /// @notice View the bid at the back of the queue
    /// @return bidHandle The encrypted bid handle
    function peekBack() external view returns (euint128 bidHandle) {
        bidHandle = bytes32ToEuint(queue.back());
    }

    /// @notice Clear all bids from the queue
    function clear() external {
        while (!queue.empty()) {
            queue.popFront();
        }
    }

    /// @notice Internal function to convert euint128 to bytes32
    /// @param input The euint128 to convert
    /// @return output The bytes32 representation
    function euintToBytes32(euint128 input) private pure returns (bytes32 output) {
        output = bytes32(euint128.unwrap(input));
    }

    /// @notice Internal function to convert bytes32 to euint128
    /// @param input The bytes32 to convert
    /// @return output The euint128 representation
    function bytes32ToEuint(bytes32 input) private pure returns (euint128 output) {
        output = euint128.wrap(uint256(input));
    }
}
