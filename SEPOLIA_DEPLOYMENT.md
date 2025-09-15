# Sepolia Deployment Guide

## Quick Start

### 1. Mine Hook Address
```bash
forge script script/SepoliaHookMiner.sol \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY
```

### 2. Deploy with Mined Salt
```bash
forge script script/SepoliaDeployment.s.sol \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --sig "run(bytes32)" \
  [MINED_SALT]
```

## Configuration

### Environment Variables
```bash
# Required in .env
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
RPC_URL=https://eth-sepolia.g.alchemy.com/v2/j0O7jiy5YQ700J97aerquWdUVZ6dihW5
ETHERSCAN_API_KEY=your_etherscan_api_key
```

### Network Details
- **Chain ID**: 11155111 (Sepolia)
- **PoolManager**: `0xE03A1074c86CFeDd5C142C4F04F1a1536e203543`
- **Network**: Ethereum Sepolia Testnet

## Hook Address Mining

The hook address must satisfy Uniswap v4 requirements based on permissions:
- `afterInitialize`: true
- `beforeAddLiquidity`: true  
- `beforeSwap`: true
- `afterSwap`: true

Required flags: `0x6800` (26624 decimal)

## Deployment Process

### Step 1: Hook Mining
```bash
# Mine a valid hook address
forge script script/SepoliaHookMiner.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY

# Example output:
# Valid Hook Address: 0x...
# Salt (bytes32): 0x00000000000000000000000000000000000000000000000000000000000012ab
```

### Step 2: Deployment
```bash
# Deploy using the mined salt
forge script script/SepoliaDeployment.s.sol \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --sig "run(bytes32)" \
  0x00000000000000000000000000000000000000000000000000000000000012ab
```

### Step 3: Verification
The deployment script automatically:
- Validates hook address matches permissions
- Verifies PoolManager integration
- Deploys supporting tokens
- Emits deployment events

## Contract Addresses

After deployment, update these addresses in your configuration:

```solidity
// Sepolia deployment addresses
address constant POOL_MANAGER = 0xE03A1074c86CFeDd5C142C4F04F1a1536e203543;
address constant STEALTH_AUCTION_HOOK = 0x...; // From deployment
address constant AUCTION_TOKEN = 0x...;        // From deployment  
address constant BASE_TOKEN = 0x...;           // From deployment
```

## Testing Deployment

### Verify Hook Registration
```bash
cast call $STEALTH_AUCTION_HOOK "poolManager()" --rpc-url $RPC_URL
# Should return: 0xE03A1074c86CFeDd5C142C4F04F1a1536e203543
```

### Check Hook Permissions
```bash
cast call $STEALTH_AUCTION_HOOK "getHookPermissions()" --rpc-url $RPC_URL
# Should return struct with correct boolean flags
```

## Troubleshooting

### Invalid Hook Address
If deployment fails with "HookAddressNotValid":
1. Ensure you're using the correct mined salt
2. Verify the PoolManager address is correct
3. Check your deployer address matches the mining process

### Mining Takes Too Long
- Mining may take several minutes to find a valid salt
- Consider running locally then using the salt on testnet
- Monitor progress logs every 50k iterations

### Verification Issues
If Etherscan verification fails:
- Ensure you have ETHERSCAN_API_KEY set
- Constructor arguments are automatically handled
- Manual verification can be done on Etherscan UI

## Gas Estimates

- Hook Deployment: ~2.5M gas
- Token Deployments: ~1.2M gas each
- Total: ~5M gas
- At 20 gwei: ~0.1 ETH

## Next Steps

1. **Frontend Integration**: Update contract addresses
2. **Pool Creation**: Create test pools with the hook
3. **Auction Testing**: Deploy sample encrypted auctions
4. **Monitoring**: Set up event monitoring for the hook
