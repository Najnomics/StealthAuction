"use client";

import { useCallback, useState } from "react";
import { useEncryptInput } from "./useEncryptInput";
import { FheTypes } from "@cofhe/sdk";
import { IntegerInput, IntegerVariant } from "~~/components/scaffold-eth";
import { useScaffoldReadContract, useScaffoldWriteContract } from "~~/hooks/scaffold-eth";

/**
 * StealthAuctionComponent - A demonstration of Fully Homomorphic Encryption (FHE) in a Dutch Auction system
 *
 * This component showcases how to:
 * 1. Create encrypted auctions with private parameters
 * 2. Submit encrypted bids
 * 3. View auction status and encrypted values
 * 4. Interact with FHE-enabled auction smart contracts
 *
 * All auction parameters (start price, end price, duration) and bids are encrypted,
 * ensuring complete privacy throughout the auction lifecycle.
 */

export const StealthAuctionComponent = () => {
  return (
    <div className="flex flex-col bg-base-100 px-10 py-10 text-center items-start rounded-3xl gap-4">
      <h2 className="font-bold text-2xl">StealthAuction Hook</h2>
      <p className="text-sm text-gray-500">MEV-Resistant Confidential Auctions on Uniswap v4</p>
      
      <div className="divider"></div>
      
      <CreateAuctionSection />
      
      <div className="divider"></div>
      
      <SubmitBidSection />
      
      <div className="divider"></div>
      
      <AuctionStatusSection />
    </div>
  );
};

/**
 * CreateAuctionSection Component
 *
 * Allows users to create a new encrypted auction with:
 * - Encrypted start price
 * - Encrypted end price
 * - Encrypted duration
 * - Encrypted supply
 */
const CreateAuctionSection = () => {
  const [startPrice, setStartPrice] = useState<string>("");
  const [endPrice, setEndPrice] = useState<string>("");
  const [duration, setDuration] = useState<string>("");
  const [supply, setSupply] = useState<string>("");
  const [poolId, setPoolId] = useState<string>("0x0c56b1dff56eeb29fe1b331374432ac762affcadedfeaf73ee6536e752213fb8");
  
  const { isPending, writeContractAsync } = useScaffoldWriteContract({ contractName: "StealthAuction" });
  const { onEncryptInput, isEncryptingInput, inputEncryptionDisabled } = useEncryptInput();

  const handleCreateAuction = useCallback(async () => {
    if (!startPrice || !endPrice || !duration || !supply) return;

    try {
      // Encrypt all auction parameters
      const encryptedStartPrice = await onEncryptInput(FheTypes.Uint128, startPrice);
      const encryptedEndPrice = await onEncryptInput(FheTypes.Uint128, endPrice);
      const encryptedDuration = await onEncryptInput(FheTypes.Uint64, duration);
      const encryptedSupply = await onEncryptInput(FheTypes.Uint128, supply);

      // Convert poolId string to bytes32
      const poolIdBytes = poolId.startsWith("0x") ? poolId : `0x${poolId}`;
      
      // Decay rate (100 = 1% per second)
      const decayRate = 100;

      // Call createEncryptedAuction
      await writeContractAsync({
        functionName: "createEncryptedAuction",
        args: [
          poolIdBytes,
          "0x86e3EA2C1593A8D7Aa84e872DD9c988D053a9aC9", // Auction token address
          encryptedStartPrice,
          encryptedEndPrice,
          encryptedDuration,
          encryptedSupply,
          decayRate,
        ],
      });
    } catch (error) {
      console.error("Error creating auction:", error);
    }
  }, [startPrice, endPrice, duration, supply, poolId, writeContractAsync, onEncryptInput]);

  const pending = isPending || isEncryptingInput;

  return (
    <div className="w-full">
      <h3 className="font-bold text-lg mb-4">Create New Auction</h3>
      <div className="flex flex-col gap-3">
        <div className="flex flex-row gap-2 items-center">
          <label className="w-32 text-left">Pool ID:</label>
          <input
            type="text"
            className="input input-bordered flex-1"
            value={poolId}
            onChange={(e) => setPoolId(e.target.value)}
            placeholder="0x..."
          />
        </div>
        <div className="flex flex-row gap-2 items-center">
          <label className="w-32 text-left">Start Price:</label>
          <IntegerInput
            value={startPrice}
            onChange={setStartPrice}
            variant={IntegerVariant.UINT128}
            disableMultiplyBy1e18
            placeholder="1000000000000000000"
          />
        </div>
        <div className="flex flex-row gap-2 items-center">
          <label className="w-32 text-left">End Price:</label>
          <IntegerInput
            value={endPrice}
            onChange={setEndPrice}
            variant={IntegerVariant.UINT128}
            disableMultiplyBy1e18
            placeholder="100000000000000000"
          />
        </div>
        <div className="flex flex-row gap-2 items-center">
          <label className="w-32 text-left">Duration:</label>
          <IntegerInput
            value={duration}
            onChange={setDuration}
            variant={IntegerVariant.UINT64}
            disableMultiplyBy1e18
            placeholder="3600"
          />
        </div>
        <div className="flex flex-row gap-2 items-center">
          <label className="w-32 text-left">Supply:</label>
          <IntegerInput
            value={supply}
            onChange={setSupply}
            variant={IntegerVariant.UINT128}
            disableMultiplyBy1e18
            placeholder="1000000000000000000000"
          />
        </div>
        <button
          className={`btn btn-primary ${pending ? "btn-disabled" : ""} ${!startPrice || !endPrice || !duration || !supply || inputEncryptionDisabled ? "btn-disabled" : ""}`}
          onClick={handleCreateAuction}
        >
          {pending && <span className="loading loading-spinner loading-xs"></span>}
          Create Auction
        </button>
      </div>
    </div>
  );
};

/**
 * SubmitBidSection Component
 *
 * Allows users to submit encrypted bids to an auction
 */
const SubmitBidSection = () => {
  const [auctionId, setAuctionId] = useState<string>("");
  const [bidAmount, setBidAmount] = useState<string>("");
  
  const { isPending, writeContractAsync } = useScaffoldWriteContract({ contractName: "StealthAuction" });
  const { onEncryptInput, isEncryptingInput, inputEncryptionDisabled } = useEncryptInput();

  const handleSubmitBid = useCallback(async () => {
    if (!auctionId || !bidAmount) return;

    try {
      // Encrypt the bid amount
      const encryptedBid = await onEncryptInput(FheTypes.Uint128, bidAmount);

      // Submit encrypted bid
      await writeContractAsync({
        functionName: "submitEncryptedBid",
        args: [BigInt(auctionId), encryptedBid],
      });
    } catch (error) {
      console.error("Error submitting bid:", error);
    }
  }, [auctionId, bidAmount, writeContractAsync, onEncryptInput]);

  const pending = isPending || isEncryptingInput;

  return (
    <div className="w-full">
      <h3 className="font-bold text-lg mb-4">Submit Bid</h3>
      <div className="flex flex-col gap-3">
        <div className="flex flex-row gap-2 items-center">
          <label className="w-32 text-left">Auction ID:</label>
          <IntegerInput
            value={auctionId}
            onChange={setAuctionId}
            variant={IntegerVariant.UINT256}
            disableMultiplyBy1e18
            placeholder="1"
          />
        </div>
        <div className="flex flex-row gap-2 items-center">
          <label className="w-32 text-left">Bid Amount:</label>
          <IntegerInput
            value={bidAmount}
            onChange={setBidAmount}
            variant={IntegerVariant.UINT128}
            disableMultiplyBy1e18
            placeholder="1000000000000000000"
          />
        </div>
        <button
          className={`btn btn-primary ${pending ? "btn-disabled" : ""} ${!auctionId || !bidAmount || inputEncryptionDisabled ? "btn-disabled" : ""}`}
          onClick={handleSubmitBid}
        >
          {pending && <span className="loading loading-spinner loading-xs"></span>}
          Submit Encrypted Bid
        </button>
      </div>
    </div>
  );
};

/**
 * AuctionStatusSection Component
 *
 * Displays auction status and encrypted values
 */
const AuctionStatusSection = () => {
  const [auctionId, setAuctionId] = useState<string>("1");

  // Read auction data (this would need to be implemented based on your contract's view functions)
  const { data: auctionData } = useScaffoldReadContract({
    contractName: "StealthAuction",
    functionName: "auctions",
    args: auctionId ? [BigInt(auctionId)] : undefined,
  });

  return (
    <div className="w-full">
      <h3 className="font-bold text-lg mb-4">Auction Status</h3>
      <div className="flex flex-col gap-3">
        <div className="flex flex-row gap-2 items-center">
          <label className="w-32 text-left">Auction ID:</label>
          <IntegerInput
            value={auctionId}
            onChange={setAuctionId}
            variant={IntegerVariant.UINT256}
            disableMultiplyBy1e18
            placeholder="1"
          />
        </div>
        {auctionData && (
          <div className="flex flex-col gap-2 p-4 bg-base-200 rounded-lg">
            <p className="text-sm text-gray-500">Auction data loaded (encrypted)</p>
            {/* Display encrypted auction parameters here */}
          </div>
        )}
      </div>
    </div>
  );
};
