# Deployment Summary

## Local Anvil Deployment (Testnet)

**Deployment Date**: February 2, 2026
**Network**: Anvil (Local Chain ID: 31337)
**Deployer**: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

### Deployed Contracts

| Contract | Address |
|----------|---------|
| AgentReputation | `0x5FbDB2315678afecb367f032d93F642f64180aa3` |
| AgentMarketplace | `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512` |

### Test Agents (Pre-registered)

| Agent | Address |
|-------|---------|
| Test Agent 1 | `0x1234567890123456789012345678901234567891` |
| Test Agent 2 | `0x1234567890123456789012345678901234567892` |

### Gas Usage

- **AgentReputation Deployment**: ~1.5M gas
- **AgentMarketplace Deployment**: ~2.8M gas
- **Total Deployment Gas**: ~5.8M gas
- **Total Cost**: 0.0116 ETH (at 2 gwei)

### Contract Verification

✅ All contracts compiled successfully
✅ All tests passing (34/34)
✅ Deployment successful
✅ Marketplace address set in reputation contract
✅ Test agents registered

## Testing the Deployment

### Verify Contracts are Live

```bash
# Check reputation contract
cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 "marketplace()(address)" --rpc-url http://127.0.0.1:8545

# Check marketplace contract
cast call 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "reputationContract()(address)" --rpc-url http://127.0.0.1:8545

# Check agent reputation
cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 "getReputation(address)(int256)" 0x1234567890123456789012345678901234567891 --rpc-url http://127.0.0.1:8545
```

### Create a Test Listing

```bash
# Using cast to interact with the contract
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
export MARKETPLACE=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
export SELLER=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
export AGENT1=0x1234567890123456789012345678901234567891

cast send $MARKETPLACE \
  "listItem(string,uint256,address,address)(uint256)" \
  '{"name":"Test Item","price":"1 ETH"}' \
  1000000000000000000 \
  $SELLER \
  $AGENT1 \
  --private-key $PRIVATE_KEY \
  --rpc-url http://127.0.0.1:8545
```

## Base Sepolia Deployment (Testnet)

> ⏳ Not yet deployed to Base Sepolia

To deploy to Base Sepolia:

```bash
export PRIVATE_KEY=your_private_key
export BASE_SEPOLIA_RPC=https://sepolia.base.org

forge script script/Deploy.s.sol:Deploy \
  --rpc-url $BASE_SEPOLIA_RPC \
  --broadcast \
  --verify
```

## Base Mainnet Deployment

> 🚫 Not deployed to mainnet (this is an MVP for testing)

## Next Steps

1. ✅ Smart contracts deployed and tested
2. ⏳ Backend API integration (see `../api/`)
3. ⏳ OpenClaw plugin integration (see `../plugin/`)
4. ⏳ End-to-end testing with real agents

## Integration with Backend API

The backend API should connect to these contracts using the addresses above:

```typescript
// api/.env
REPUTATION_CONTRACT_ADDRESS=0x5FbDB2315678afecb367f032d93F642f64180aa3
MARKETPLACE_CONTRACT_ADDRESS=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
RPC_URL=http://127.0.0.1:8545
```

## Contract ABIs

Contract ABIs are available in:
- `out/AgentMarketplace.sol/AgentMarketplace.json`
- `out/AgentReputation.sol/AgentReputation.json`

Export ABIs for API integration:

```bash
# Export marketplace ABI
cat out/AgentMarketplace.sol/AgentMarketplace.json | jq .abi > ../api/src/abi/AgentMarketplace.json

# Export reputation ABI
cat out/AgentReputation.sol/AgentReputation.json | jq .abi > ../api/src/abi/AgentReputation.json
```

## Monitoring Events

The contracts emit the following events for API indexing:

### AgentMarketplace Events

- `ListingCreated(uint256 listingId, address seller, address sellerAgent, uint256 price, string itemData, uint256 timestamp)`
- `PurchaseRequested(uint256 listingId, address buyer, address buyerAgent, uint256 timestamp)`
- `PurchaseConfirmed(uint256 listingId, address seller, uint256 timestamp)`
- `FundsReleased(uint256 listingId, address seller, uint256 amount, uint256 timestamp)`
- `ListingRefunded(uint256 listingId, address buyer, uint256 amount, uint256 timestamp)`
- `ListingCancelled(uint256 listingId, address seller, uint256 timestamp)`

### AgentReputation Events

- `AgentRegistered(address agent, uint256 timestamp)`
- `ReputationUpdated(address agent, int256 newReputation, int256 change, string reason, uint256 timestamp)`

---

**Status**: ✅ Local deployment complete and verified
**Last Updated**: February 2, 2026
