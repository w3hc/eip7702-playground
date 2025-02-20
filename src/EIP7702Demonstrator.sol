// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title EIP-7702 Demonstrator
/// @notice Helper contract to demonstrate EIP-7702 functionality
/// @dev Provides utilities for checking EOA code status
contract EIP7702Demonstrator {
    /// @notice Get the code size of an account
    /// @param account The address to check
    /// @return The size of the code at the address
    function getCodeLength(address account) external view returns (uint256) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size;
    }
}
