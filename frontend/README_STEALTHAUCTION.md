# StealthAuction Frontend Setup

This frontend is based on the [CoFHE Scaffold-ETH template](https://github.com/FhenixProtocol/cofhe-scaffold-eth) and has been configured to work with the StealthAuction contracts deployed on Base Sepolia.

## Quick Start

1. **Install dependencies:**
   ```bash
   cd frontend
   yarn install
   ```

2. **Start the development server:**
   ```bash
   yarn start
   ```

3. **Open your browser:**
   Navigate to `http://localhost:3000`

## Configuration

### Network Configuration
- **Base Sepolia** (Chain ID: 84532) has been added to `targetNetworks` in `packages/nextjs/scaffold.config.ts`
- RPC URL: `https://sepolia.base.org`

### Deployed Contracts (Base Sepolia)

- **StealthAuction Hook**: `0xb6931e230A16823E8237d90b010F519f661B48C0`
- **StealthAuctionToken**: `0x86e3EA2C1593A8D7Aa84e872DD9c988D053a9aC9`
- **Pool ID**: `0x0c56b1dff56eeb29fe1b331374432ac762affcadedfeaf73ee6536e752213fb8`

### Contract ABIs
- ABIs have been extracted to `packages/nextjs/contracts/abis/`
- Contracts are configured in `packages/nextjs/contracts/deployedContracts.ts`

## Features

The frontend includes a `StealthAuctionComponent` that allows users to:

1. **Create Encrypted Auctions**
   - Set encrypted start price, end price, duration, and supply
   - All parameters are encrypted using CoFHE before being sent to the blockchain

2. **Submit Encrypted Bids**
   - Submit bids with encrypted amounts
   - Bids remain private until auction settlement

3. **View Auction Status**
   - View encrypted auction data
   - Decrypt values with proper permits

## Components

- **StealthAuctionComponent**: Main component for auction interactions
- **CreateAuctionSection**: Form to create new encrypted auctions
- **SubmitBidSection**: Form to submit encrypted bids
- **AuctionStatusSection**: Display auction status and encrypted values

## Environment Variables

Create a `.env.local` file in `packages/nextjs/` with:

```env
NEXT_PUBLIC_ALCHEMY_API_KEY=your_alchemy_api_key
NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID=your_walletconnect_project_id
```

## Notes

- The frontend uses CoFHE SDK for encryption/decryption operations
- All FHE operations require proper initialization and permits
- Make sure you're connected to Base Sepolia network
- The auction token address is hardcoded in the component - update if needed

## Troubleshooting

1. **ABI Import Issues**: If you see import errors, make sure the ABIs are properly formatted JSON files
2. **Network Connection**: Ensure you're connected to Base Sepolia (Chain ID: 84532)
3. **CoFHE Initialization**: Make sure CoFHE is properly initialized before using encryption features

## Next Steps

1. Update `deployedContracts.ts` to properly inline the ABIs (currently using require())
2. Add more auction management features (settle, reveal, etc.)
3. Add better error handling and user feedback
4. Add auction list/explorer view
5. Integrate with Uniswap v4 pool interactions
