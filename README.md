# EIP-7702 Playground

This repository demonstrates [EIP-7702](https://eip7702.io/): EOA Code Setting, a significant Ethereum upgrade introduced in [Pectra upgrade](https://ethereum.org/en/roadmap/pectra/#new-improvements).

[View Asciinema demo](https://asciinema.org/a/704589)

## What is EIP-7702?

EIP-7702 allows Externally Owned Accounts (EOAs) to have code through a delegation mechanism. This brings smart contract capabilities to EOAs without requiring users to migrate to new accounts.

### Key Features

- Set delegation code on EOAs
- Execute contract code in EOA context
- Maintain EOA transaction signing ability
- Support for cross-chain authorizations

### Use Cases

- Transaction batching
- Gas sponsorship
- Granular permissions
- Account abstraction features

## Sponsored Transfer Example

Our repository includes a complete example of gas sponsorship using EIP-7702:

```solidity
// Alice authorizes Sponsor contract
bytes memory code = abi.encodePacked(hex"ef0100", address(sponsor));
vm.etch(alice, code);  // Sets delegation code

// Execute sponsored transfer where:
// 1. Relayer pays gas
// 2. Value comes from Alice
// 3. Bob receives the transfer
vm.prank(alice);
address(alice).call{value: 1 ether}(
    abi.encodeWithSelector(Sponsor.sponsoredTransfer.selector, bob)
);
```

### Who Pays What

| Party | Pays |
|-------|------|
| Alice | Transfer value (e.g., 1 ETH) |
| Relayer | Gas fees |
| Bob | Nothing (recipient) |

## Technical Details

### Delegation Format
```solidity
bytes memory delegationCode = abi.encodePacked(
    hex"ef0100",        // EIP-7702 magic bytes
    address(contract)   // Target contract address
);
```

### Example Usage
```solidity
// Create a sponsor contract
Sponsor sponsor = new Sponsor();

// Set delegation on EOA (only works in Prague+)
bytes memory code = abi.encodePacked(hex"ef0100", address(sponsor));
vm.etch(eoa, code);  // Sets delegation code

// Any call to EOA is delegated to sponsor contract
// but executes in EOA's context
```

## Testing

The repository includes tests that verify EIP-7702 functionality across different EVM versions:

```bash
# Should pass - Prague supports EIP-7702
FOUNDRY_PROFILE=prague forge test

# Alternatively
pnpm test

# Should fail - Shanghai doesn't support EIP-7702
FOUNDRY_PROFILE=shanghai forge test

# Alternatively
pnpm test:shanghai
```

### Test Structure

- `src/Sponsor.sol`: Example contract for gas sponsorship
- `src/EIP7702Demonstrator.sol`: Helper contract for demonstrations
- `test/SponsoredTransferTest.t.sol`: Test suite showing sponsored transfers
- `test/EIP7702Support.t.sol`: Test suite for EVM version compatibility

## Prerequisites

- Foundry `v1.0` (learn more [here](https://www.paradigm.xyz/2025/02/announcing-foundry-v1-0))

## Installation

```bash
forge install
```

## Development

```bash
# Build
forge build

# Test with specific EVM version
FOUNDRY_PROFILE=prague forge test -vvv
```

### Deploy

First, start a local Anvil node:

```sh
anvil
```

Then in a new terminal, deploy using one of the following commands:

Deploy with default (Prague) settings:
```sh
forge script script/Deploy.s.sol --broadcast --fork-url http://localhost:8545
```

Deploy with Prague profile explicitly:
```sh
FOUNDRY_PROFILE=prague forge script script/Deploy.s.sol --broadcast --fork-url http://localhost:8545
```

Deploy with Shanghai profile:
```sh
FOUNDRY_PROFILE=shanghai forge script script/Deploy.s.sol --broadcast --fork-url http://localhost:8545
```

For these scripts to work, you need to have a `MNEMONIC` environment variable set to a valid
[BIP39 mnemonic](https://iancoleman.io/bip39/).

For instructions on how to deploy to a testnet or mainnet, check out the
[Solidity Scripting](https://book.getfoundry.sh/guides/scripting-with-solidity) tutorial.

## Key Differences: Prague vs Shanghai

| Feature | Prague | Shanghai |
|---------|---------|-----------|
| Set EOA Code | ✅ | ❌ |
| Code Size | 23 bytes | 0 bytes |
| Delegation | Supported | Not Supported |
| Gas Sponsorship | ✅ | ❌ |

## Example Test Output

```
=== EIP-7702 Sponsored Transfer Details ===
Delegation code size: 23
Gas used: 68690
Value transferred: 1000000000000000000
Sender (Alice) balance change: 1000000000000000000
Recipient (Bob) balance change: 1000000000000000000
```

## Support

Feel free to reach out to [Julien](https://github.com/julienbrg) through:

- Element: [@julienbrg:matrix.org](https://matrix.to/#/@julienbrg:matrix.org)
- Farcaster: [julien-](https://warpcast.com/julien-)
- Telegram: [@julienbrg](https://t.me/julienbrg)
- Twitter: [@julienbrg](https://twitter.com/julienbrg)
- Discord: [julienbrg](https://discordapp.com/users/julienbrg)
- LinkedIn: [julienberanger](https://www.linkedin.com/in/julienberanger/)

<img src="https://bafkreid5xwxz4bed67bxb2wjmwsec4uhlcjviwy7pkzwoyu5oesjd3sp64.ipfs.w3s.link" alt="built-with-ethereum-w3hc" width="100"/>
