# StealthAuction Deployment & Demo Guide

## Quick Start

### Prerequisites
- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Node.js and npm/yarn (for any frontend integration)
- Git

### One-Command Deployment & Demo
```bash
# Deploy to local Anvil network and run full demo
./deploy.sh

# Deploy to specific network
./deploy.sh sepolia
```

## Manual Deployment Steps

### 1. Environment Setup
```bash
# Clone and setup
git clone <repository>
cd StealthAuction

# Install dependencies
pnpm install

# Compile contracts
forge build
```

### 2. Run Tests
```bash
# Run full test suite
forge test

# Run specific test contract
forge test --match-contract "StealthAuctionTest"

# Verbose output for debugging
forge test --match-contract "StealthAuctionTest" -vvv
```

### 3. Deploy Contracts

#### Local Development (Anvil)
```bash
# Start local network
anvil

# Deploy in new terminal
forge script script/DeployStealthAuction.s.sol:DeployStealthAuction \
  --rpc-url http://localhost:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  --broadcast
```

#### Testnet Deployment (Sepolia)
```bash
# Set environment variables
export PRIVATE_KEY=your_private_key
export RPC_URL=https://eth-sepolia.g.alchemy.com/v2/your_api_key

# Deploy
forge script script/DeployStealthAuction.s.sol:DeployStealthAuction \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify
```

### 4. Run Demo
```bash
# After deployment, run the interactive demo
forge script script/StealthAuctionDemo.s.sol:StealthAuctionDemo \
  --rpc-url http://localhost:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  --broadcast
```

## Demo Walkthrough

The demo demonstrates the complete FHE Dutch auction lifecycle:

### Phase 1: Auction Creation
- Seller creates encrypted auction with hidden parameters
- Start price, end price, duration, and supply are encrypted
- Hook permissions are properly configured

### Phase 2: Bidding Process
- Multiple bidders submit encrypted bids
- Bid amounts remain private on-chain
- Real-time auction state tracking

### Phase 3: Price Decay
- Demonstrates encrypted price decay over time
- Shows auction status checks
- Time-based price calculations using FHE

### Phase 4: Settlement
- Auction settles with encrypted computations
- Winning bids determined privately
- Token distributions calculated without revealing amounts

### Phase 5: Parameter Revelation
- Optional seller-controlled parameter reveal
- Post-auction transparency mechanism
- Auction fairness verification

## Architecture Overview

### Core Components
1. **StealthAuction Hook** - Main auction logic with 4 hook integrations
2. **StealthAuctionToken** - FHE-enabled ERC20 tokens
3. **BidQueue** - Encrypted bid management
4. **FHEPermissions** - Cryptographic access control
5. **AuctionLibrary** - Utility functions

### Hook Integration
- `beforeSwap` - Auction-aware swap processing
- `afterSwap` - Post-swap auction updates
- `afterInitialize` - Pool initialization handling
- `beforeAddLiquidity` - Liquidity addition validation

### FHE Features
- Encrypted auction parameters
- Private bid submissions
- Confidential price decay calculations
- Secure settlement computations

## Contract Addresses

After deployment, addresses are saved to `.env`:
```bash
STEALTH_AUCTION_HOOK=0x...
TOKEN0=0x...
TOKEN1=0x...
AUCTION_TOKEN=0x...
POOL_MANAGER=0x...
```

## Testing

### Test Categories
- **Unit Tests** - Individual contract functionality
- **Integration Tests** - Cross-contract interactions
- **FHE Tests** - Encryption/decryption workflows
- **Hook Tests** - Uniswap v4 integration
- **Stress Tests** - High-load scenarios

### Key Test Results
✅ 24/24 tests passing  
✅ Complete FHE integration  
✅ All hook permissions validated  
✅ Auction lifecycle coverage  
✅ Error handling verification  

## Gas Optimization

Current gas usage (approximate):
- Auction Creation: ~2.1M gas
- Bid Submission: ~4.8M gas
- Settlement: ~8.8M gas

## Security Considerations

### FHE Security
- All sensitive data encrypted on-chain
- Private key management for FHE operations
- Access control through FHEPermissions

### Hook Security
- Proper permission validation
- Reentrancy protection
- Owner-only administrative functions

### Audit Checklist
- [ ] FHE encryption/decryption paths
- [ ] Hook permission boundaries
- [ ] Token approval mechanisms
- [ ] Settlement calculation accuracy

## Troubleshooting

### Common Issues
1. **Hook deployment fails** - Check flag calculation
2. **FHE operations fail** - Verify signer permissions
3. **Tests timeout** - Increase gas limits
4. **Demo script fails** - Check environment variables

### Debug Commands
```bash
# Verbose test output
forge test -vvvv

# Gas reporting
forge test --gas-report

# Coverage analysis
forge coverage --ir-minimum

# Static analysis
slither .
```

## Next Steps

### Production Deployment
1. Audit smart contracts
2. Deploy to mainnet
3. Set up monitoring
4. Create frontend interface

### Feature Extensions
1. Multi-token auctions
2. Batch auction processing
3. Advanced bidding strategies
4. MEV protection mechanisms

## Support

For issues and questions:
- Review test cases in `test/StealthAuction.t.sol`
- Check deployment logs in `deployment-summary.md`
- Examine contract code in `src/`

---

**Note**: This is a demonstration system. Conduct thorough testing and auditing before production use.
