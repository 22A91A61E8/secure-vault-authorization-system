# Authorization-Governed Vault System

A secure smart contract system implementing authorization-governed asset withdrawals with ECDSA signature verification and replay attack prevention.

## Overview

This project implements a two-contract system for managing secure withdrawals from a vault:

1. **AuthorizationManager**: Validates withdrawal permissions using ECDSA signatures
2. **SecureVault**: Holds funds and executes withdrawals only after authorization validation

## Architecture

### System Design

The system separates concerns between asset custody and permission validation:

```
┌─────────────────┐         ┌──────────────────────┐
│  SecureVault    │◄────────│ AuthorizationManager │
│                 │ Verify  │                      │
│ - Hold funds    │────────►│ - Validate signature │
│ - Execute       │         │ - Track nonces       │
│   withdrawals   │         │ - Prevent replay     │
└─────────────────┘         └──────────────────────┘
        ▲                            ▲
        │                            │
        │                            │
     Deposits                   Off-chain
     Withdrawals               Authorization
```

### Authorization Flow

1. Off-chain service generates signed authorization containing:
   - Vault address (contract binding)
   - Recipient address
   - Withdrawal amount
   - Unique nonce (replay protection)
   - Chain ID (network binding)

2. User calls `withdraw()` on SecureVault with authorization
3. SecureVault calls AuthorizationManager to verify
4. Authorization is marked as used (can't be reused)
5. If valid, withdrawal executes

### Security Features

- **Signature Verification**: Uses ECDSA to verify authorizations
- **Replay Protection**: Each authorization has a unique nonce tracked on-chain
- **Network Binding**: Chain ID prevents cross-chain replay attacks
- **Contract Binding**: Authorization includes vault address
- **Checks-Effects-Interactions**: State updated before external calls
- **Initialization Protection**: Contracts can only be initialized once

## Smart Contracts

### AuthorizationManager.sol

**Purpose**: Validates and tracks withdrawal authorizations

**Key Functions**:
- `verifyAuthorization()`: Validates signature and marks authorization as used
- `isAuthorizationUsed()`: Checks if authorization has been consumed
- `updateSigner()`: Updates the authorized signer address

**Security Properties**:
- Prevents authorization reuse
- Validates signer identity
- Tracks all consumed authorizations

### SecureVault.sol

**Purpose**: Holds funds and executes authorized withdrawals

**Key Functions**:
- `receive()`: Accepts deposits
- `withdraw()`: Executes withdrawals with valid authorization
- `getBalance()`: Returns vault balance

**Security Properties**:
- Only processes valid authorizations
- Updates state before transferring value
- Emits events for observability

## Project Structure

```
/
├── contracts/
│   ├── AuthorizationManager.sol
│   └── SecureVault.sol
├── scripts/
│   └── deploy.js
├── docker/
│   ├── Dockerfile
│   └── entrypoint.sh
├── docker-compose.yml
├── package.json
└── README.md
```

## Local Development

### Prerequisites

- Docker
- Docker Compose

### Quick Start

1. Clone the repository:
```bash
git clone https://github.com/22A91A61E8/secure-vault-authorization-system.git
cd secure-vault-authorization-system
```

2. Start local blockchain and deploy contracts:
```bash
docker-compose up
```

This will:
- Start a local Hardhat node
- Compile smart contracts
- Deploy AuthorizationManager
- Deploy SecureVault
- Output contract addresses

### Manual Deployment

If you prefer to deploy manually:

```bash
# Install dependencies
npm install

# Compile contracts
npx hardhat compile

# Deploy contracts
node scripts/deploy.js
```

## Authorization Generation

To create a valid authorization for withdrawal:

```javascript
const { ethers } = require('ethers');

// Parameters
const vaultAddress = "0x...";
const recipient = "0x...";
const amount = ethers.parseEther("1.0");
const nonce = Date.now(); // Unique identifier
const chainId = 31337; // Hardhat local network

// Create message hash
const messageHash = ethers.solidityPackedKeccak256(
    ["address", "address", "uint256", "uint256", "uint256"],
    [vaultAddress, recipient, amount, nonce, chainId]
);

// Sign with authorized signer's private key
const signer = new ethers.Wallet(privateKey);
const signature = await signer.signMessage(ethers.getBytes(messageHash));

// Use signature in withdrawal
await vaultContract.withdraw(recipient, amount, nonce, chainId, signature);
```

## Testing

### Successful Withdrawal Test

1. Deposit funds to vault
2. Generate valid authorization
3. Call withdraw with authorization
4. Verify funds transferred
5. Verify authorization marked as used

### Replay Attack Prevention Test

1. Create and use authorization
2. Attempt to reuse same authorization
3. Verify transaction reverts

### Invalid Signature Test

1. Create authorization signed by unauthorized address
2. Attempt withdrawal
3. Verify transaction reverts

## Key Invariants

1. **Single Use**: Each authorization can only produce one state transition
2. **Non-negative Balance**: Vault balance never goes negative
3. **Authorization Binding**: Authorizations are bound to specific vault, recipient, amount
4. **Network Binding**: Authorizations include chain ID to prevent cross-chain replay
5. **Signature Validity**: Only authorized signer can create valid authorizations

## Common Issues

### Authorization Already Used
**Error**: `AuthorizationAlreadyUsed()`
**Cause**: Trying to reuse a nonce
**Solution**: Generate new authorization with unique nonce

### Invalid Signature
**Error**: `InvalidSignature()`
**Cause**: Signature not from authorized signer
**Solution**: Ensure correct private key is used for signing

### Insufficient Balance
**Error**: Transaction reverts
**Cause**: Vault doesn't have enough funds
**Solution**: Deposit more funds or reduce withdrawal amount

## Security Considerations

### Implemented Protections

✅ Replay attack prevention via nonce tracking
✅ Cross-chain replay prevention via chain ID
✅ Signature verification using ECDSA
✅ Checks-effects-interactions pattern
✅ Event emission for observability
✅ Input validation

### Best Practices Followed

- Minimal external dependencies
- Clear separation of concerns
- Comprehensive error messages
- Gas-efficient storage patterns
- Deterministic execution

## FAQ

**Q: Can I deploy to mainnet?**
A: Yes, but ensure thorough security auditing first.

**Q: How do I change the authorized signer?**
A: Call `updateSigner()` on AuthorizationManager from current signer address.

**Q: What happens if I lose my private key?**
A: Funds remain in vault, but new authorizations cannot be created without updating signer.

**Q: Can multiple people deposit to the vault?**
A: Yes, anyone can deposit. Only authorized withdrawals can remove funds.

## License

MIT

## Author

22A91A61E8
