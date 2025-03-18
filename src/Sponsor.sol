// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title Sponsor Contract for EIP-7702 Demonstration
/// @notice Demonstrates gas sponsorship capabilities using EIP-7702
/// @dev This contract acts as the delegate for EOAs, enabling sponsored transactions
contract Sponsor {
    /// @notice Thrown when the transfer of ETH fails
    error TransferFailed();
    error InvalidSignature();
    error NonceAlreadyUsed();

    /// @notice Records of gas spent by relayers
    mapping(address => uint256) public gasSpent;

    /// @notice Used nonces to prevent replay attacks
    mapping(address => uint256) public nonces;

    /// @notice Emitted when a sponsored transfer is completed
    /// @param sender The original sender (EOA)
    /// @param recipient The recipient of the transfer
    /// @param amount The amount transferred
    /// @param gasUsed The amount of gas used
    event SponsoredTransfer(address indexed sender, address indexed recipient, uint256 amount, uint256 gasUsed);

    bytes32 public constant SPONSORED_TRANSFER_TYPEHASH =
        keccak256("SponsoredTransfer(address sender,address recipient,uint256 amount,uint256 nonce)");

    bytes32 public immutable DOMAIN_SEPARATOR;

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("Sponsor")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    /// @notice Execute a transfer on behalf of msg.sender and records gas usage
    /// @param sender The address that authorized the transfer
    /// @param recipient The address to receive the ETH
    /// @param amount The amount to transfer
    /// @param nonce The unique nonce to prevent replay attacks
    /// @param v Recovery byte of the sender's signature
    /// @param r First 32 bytes of the sender's signature
    /// @param s Second 32 bytes of the sender's signature
    function sponsoredTransfer(
        address sender,
        address payable recipient,
        uint256 amount,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        payable
    {
        // Ensure nonce is not reused
        if (nonce != nonces[sender]++) revert NonceAlreadyUsed();

        // Compute expected message hash
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(SPONSORED_TRANSFER_TYPEHASH, sender, recipient, amount, nonce))
            )
        );

        // Recover signer from signature
        address recovered = ecrecover(digest, v, r, s);
        if (recovered == address(0) || recovered != sender) revert InvalidSignature();

        // Store initial gas for measurement
        uint256 startGas = gasleft();

        // Execute the transfer
        (bool success,) = recipient.call{ value: amount }("");
        if (!success) revert TransferFailed();

        // Calculate and record gas usage
        uint256 gasUsed = startGas - gasleft();
        gasSpent[sender] += gasUsed;

        emit SponsoredTransfer(sender, recipient, amount, gasUsed);
    }
}
