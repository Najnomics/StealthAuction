# **Encrypted Dutch Auction Hook**

Enables confidential Dutch auctions on Uniswap v4 - encrypting starting price, decay parameters, and bidding progress to prevent sniping while maintaining fair price discovery.

**Flow:** Encrypted auction parameters set → Hidden price decay computed homomorphically → Traders submit encrypted bids → FHE comparison against current price → Execution only on winning bid → Optional parameter reveal post-settlement.

## **Business Impact**

- **Execute large token sales without revealing strategy**—eliminate front-running and bid sniping while preserving natural price discovery.
- **Enable fair liquidation auctions** for protocols and lending platforms without telegraphing desperation or reserves.
- **Support treasury diversification and fundraising** with encrypted reserves, timeline flexibility, and protection from coordination attacks.

## **Technical Architecture**

### **Core Components**

```
src/
├── EncryptedDutchAuction.sol    # Main Uniswap v4 hook contract
├── BaseHook.sol                 # Base hook implementation
test/
├── EncryptedDutchAuction.t.sol  # Comprehensive test suite
script/
├── Deploy.s.sol                 # Deployment script
├── Demo.s.sol                   # Demo script with sample auctions
frontend/
├── src/
│   ├── components/
│   │   ├── EncryptedBidder.tsx     # Encrypted bidding interface
│   │   ├── AuctionCreator.tsx      # Auction creation interface
│   │   └── AuctionViewer.tsx       # Auction monitoring interface
│   └── hooks/
│       └── useCoFHE.tsx            # CoFHE.js integration hooks
```

### **FHE Integration**

**Encrypted Data Types:**
- `euint128` - Auction prices, bid amounts, token supplies
- `euint64` - Time parameters, durations
- `ebool` - Auction state flags
- `eaddress` - Encrypted addresses (when needed)

**FHE Operations:**
- `FHE.add/sub/mul/div` - Price calculations and decay
- `FHE.gte/lt` - Bid validation and price comparisons
- `FHE.select` - Conditional logic for winning bids
- `FHE.asEuintX` - Type conversions
- `FHE.decrypt` - Optional parameter revelation

### **Key Dependencies**

```toml
[dependencies]
forge-std = "github.com/foundry-rs/forge-std"
v4-core = "github.com/Uniswap/v4-core"
v4-periphery = "github.com/Uniswap/v4-periphery"
openzeppelin-contracts = "github.com/OpenZeppelin/openzeppelin-contracts"
cofhe-contracts = "github.com/FhenixProtocol/cofhe-contracts"
cofhe-mock-contracts = "github.com/FhenixProtocol/cofhe-mock-contracts"
```

## **Usage**

### **Build**
```bash
forge build
```

### **Test**
```bash
forge test
```

### **Deploy**
```bash
forge script script/Deploy.s.sol --rpc-url <fhenix_rpc> --broadcast
```

### **Demo**
```bash
forge script script/Demo.s.sol --rpc-url <fhenix_rpc> --broadcast
```

## **Integration Examples**

### **Creating an Encrypted Auction**
```solidity
// Encrypt auction parameters
euint128 encryptedStartPrice = FHE.asEuint128(1000 ether);
euint128 encryptedEndPrice = FHE.asEuint128(100 ether);
euint64 encryptedDuration = FHE.asEuint64(3600); // 1 hour

uint256 auctionId = encryptedDutchAuction.createEncryptedAuction(
    tokenAddress,
    encryptedStartPrice,
    encryptedEndPrice,
    encryptedDuration,
    tokenSupply
);
```

### **Submitting Encrypted Bids**
```solidity
// Encrypt bid amount
euint128 encryptedBid = FHE.asEuint128(500 ether);

encryptedDutchAuction.submitEncryptedBid(auctionId, encryptedBid);
```

### **Frontend Integration**
```typescript
import { useCoFHE } from './hooks/useCoFHE';

export function EncryptedBidder() {
  const { encrypt, decrypt, instance } = useCoFHE();
  
  const submitBid = async (amount: string) => {
    const encryptedAmount = await encrypt(parseEther(amount));
    await contract.submitEncryptedBid(auctionId, encryptedAmount);
  };
}
```

## **Security Features**

- **Price Privacy**: Starting/ending prices encrypted until optional reveal
- **Bid Privacy**: Individual bid amounts remain confidential
- **Progress Privacy**: Running totals computed homomorphically
- **MEV Protection**: No visible auction state prevents front-running
- **Fair Discovery**: Dutch auction mechanism ensures price discovery

## **Development Status**

✅ Core hook architecture  
✅ Basic auction mechanics  
🔄 FHE integration (in progress)  
⏳ Frontend implementation  
⏳ Comprehensive testing  
⏳ Production deployment