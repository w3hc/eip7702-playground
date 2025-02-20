# EIP-7702 Playground

This repository demonstrates [EIP-7702](https://eip7702.io/): EOA Code Setting, a significant Ethereum upgrade introduced in [Pectra upgrade](https://ethereum.org/en/roadmap/pectra/#new-improvements).

[View Asciinema demo](https://asciinema.org/a/704542)

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
// Create a demonstrator contract
EIP7702Demonstrator demonstrator = new EIP7702Demonstrator();

// Set delegation on EOA (only works in Prague+)
bytes memory code = abi.encodePacked(hex"ef0100", address(demonstrator));
vm.etch(eoa, code);  // Sets delegation code
```

## Testing

The repository includes tests that verify EIP-7702 functionality across different EVM versions:

```bash
# Should pass - Prague supports EIP-7702
FOUNDRY_PROFILE=prague forge test

# Should fail - Shanghai doesn't support EIP-7702
FOUNDRY_PROFILE=shanghai forge test
```

### Test Structure

- `src/EIP7702Demonstrator.sol`: Example contract for delegation
- `src/EIP7702Test.sol`: Helper contract for testing
- `test/EIP7702Support.t.sol`: Test suite demonstrating EIP-7702

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
FOUNDRY_PROFILE=prague forge test
```

### Deploy

First, start a local Anvil node:

```sh
$ anvil
```

Then in a new terminal, deploy using one of the following commands:

Deploy with default (Prague) settings:
```sh
$ forge script script/Deploy.s.sol --broadcast --fork-url http://localhost:8545
```

Deploy with Prague profile explicitly:
```sh
$ FOUNDRY_PROFILE=prague forge script script/Deploy.s.sol --broadcast --fork-url http://localhost:8545
```

Deploy with Shanghai profile:
```sh
$ FOUNDRY_PROFILE=shanghai forge script script/Deploy.s.sol --broadcast --fork-url http://localhost:8545
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

## Support

Feel free to reach out to [Julien](https://github.com/julienbrg) through:

- Element: [@julienbrg:matrix.org](https://matrix.to/#/@julienbrg:matrix.org)
- Farcaster: [julien-](https://warpcast.com/julien-)
- Telegram: [@julienbrg](https://t.me/julienbrg)
- Twitter: [@julienbrg](https://twitter.com/julienbrg)
- Discord: [julienbrg](https://discordapp.com/users/julienbrg)
- LinkedIn: [julienberanger](https://www.linkedin.com/in/julienberanger/)

<img src="https://bafkreid5xwxz4bed67bxb2wjmwsec4uhlcjviwy7pkzwoyu5oesjd3sp64.ipfs.w3s.link" alt="built-with-ethereum-w3hc" width="100"/>
