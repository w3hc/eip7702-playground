// SPDX-License-Identifier: MIT
pragma solidity >=0.8.28;

/// @title EIP7702Demonstrator
/// @notice A contract that demonstrates the functionality of EIP-7702
contract EIP7702Demonstrator {
    event CodeExecuted(address origin, address caller);

    /// @notice Demonstrates execution in the context of an EOA
    /// @dev This function shows that tx.origin can have code and msg.sender can equal tx.origin
    function demonstrateExecution() external {
        emit CodeExecuted(tx.origin, msg.sender);
    }
}
