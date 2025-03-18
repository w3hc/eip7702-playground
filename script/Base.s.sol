// SPDX-License-Identifier: MIT
pragma solidity >=0.8.28 <0.9.0;

import { Script } from "forge-std/src/Script.sol";

/**
 * @title BaseScript
 * @notice Base deployment script with common functionality
 * @dev Provides utilities for deterministic deployments and broadcasting
 */
abstract contract BaseScript is Script {
    /// @dev Included to enable compilation of the script without a $MNEMONIC environment variable.
    string internal constant TEST_MNEMONIC = "test test test test test test test test test test test junk";

    /// @dev Needed for the deterministic deployments.
    bytes32 internal constant ZERO_SALT = bytes32(0);

    /// @dev The address of the transaction broadcaster.
    address internal broadcaster;

    /// @dev Used to derive the broadcaster's address if $ETH_FROM is not defined.
    string internal mnemonic;

    /**
     * @notice Initializes the transaction broadcaster
     * @dev Sets up the broadcaster using one of these methods (in order):
     *      1. Use $ETH_FROM environment variable if defined
     *      2. Derive address from $MNEMONIC environment variable if defined
     *      3. Fall back to a test mnemonic for local testing
     */
    constructor() {
        address from = vm.envOr({ name: "ETH_FROM", defaultValue: address(0) });
        if (from != address(0)) {
            broadcaster = from;
        } else {
            mnemonic = vm.envOr({ name: "MNEMONIC", defaultValue: TEST_MNEMONIC });
            (broadcaster,) = deriveRememberKey({ mnemonic: mnemonic, index: 0 });
        }
    }

    /**
     * @notice Modifier to broadcast transactions from the configured broadcaster
     * @dev Wraps the function execution with vm.startBroadcast and vm.stopBroadcast
     */
    modifier broadcast() {
        vm.startBroadcast(broadcaster);
        _;
        vm.stopBroadcast();
    }
}
