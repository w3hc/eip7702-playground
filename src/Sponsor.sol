// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title Sponsor Contract for EIP-7702 Demonstration
/// @notice Demonstrates gas sponsorship capabilities using EIP-7702
/// @dev This contract acts as the delegate for EOAs, enabling sponsored transactions
contract Sponsor {
    /// @notice Thrown when the transfer of ETH fails
    error TransferFailed();

    /// @notice Records of gas spent by relayers
    mapping(address => uint256) public gasSpent;

    /// @notice Emitted when a sponsored transfer is completed
    /// @param sender The original sender (EOA)
    /// @param recipient The recipient of the transfer
    /// @param amount The amount transferred
    /// @param gasUsed The amount of gas used
    event SponsoredTransfer(address indexed sender, address indexed recipient, uint256 amount, uint256 gasUsed);

    /// @notice Execute a transfer on behalf of msg.sender and records gas usage
    /// @param recipient The address to receive the ETH
    /// @dev When called through EIP-7702, msg.sender will be the EOA
    function sponsoredTransfer(address payable recipient) external payable {
        // Store initial gas for measurement
        uint256 startGas = gasleft();

        // Record who is actually executing this (should be EOA via EIP-7702)
        address actualSender = msg.sender;

        // Execute the transfer from the sender's balance
        (bool success,) = recipient.call{ value: msg.value }("");
        if (!success) revert TransferFailed();

        // Calculate and record gas usage
        uint256 gasUsed = startGas - gasleft();
        gasSpent[tx.origin] += gasUsed;

        emit SponsoredTransfer(actualSender, recipient, msg.value, gasUsed);
    }
}
