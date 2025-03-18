// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title Sponsor
 * @notice Demonstration contract for gas sponsorship capabilities using EIP-7702
 * @dev Implements EIP-712 for secure signature validation and execution delegation
 * @custom:eip EIP-7702 (EOA Code Setting), EIP-712 (Typed structured data hashing and signing)
 */
contract Sponsor {
    /**
     * @notice Thrown when ETH transfer to recipient fails
     * @dev May occur if recipient contract has a failing fallback function
     */
    error TransferFailed();

    /**
     * @notice Thrown when signature validation fails
     * @dev May occur if signature is invalid or was not signed by the claimed sender
     */
    error InvalidSignature();

    /**
     * @notice Thrown when a nonce is reused (replay protection)
     * @dev Ensures each authorization can only be used once
     */
    error NonceAlreadyUsed();

    /**
     * @dev ERC-7201 storage namespace for Sponsor contract
     * @custom:storage-location erc7201:sponsor.storage
     */
    struct SponsorStorage {
        // Tracks gas spent by each sender when using sponsored transactions
        mapping(address => uint256) gasSpent;
        // Tracks the next valid nonce for each sender
        mapping(address => uint256) nonces;
    }

    // keccak256(abi.encode(uint256(keccak256("sponsor.storage")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 private constant SPONSOR_STORAGE_LOCATION =
        0xa185f0c1eeeb9abcce3ff812824b81cc825ec30cf022a2ea6a53b4f45b576600;

    /**
     * @dev Get the sponsor storage
     */
    function _getSponsorStorage() private pure returns (SponsorStorage storage s) {
        bytes32 position = SPONSOR_STORAGE_LOCATION;
        assembly {
            s.slot := position
        }
    }

    /// @notice Type hash for EIP-712 signature of sponsored transfers
    bytes32 public constant SPONSORED_TRANSFER_TYPEHASH =
        keccak256("SponsoredTransfer(address sender,address recipient,uint256 amount,uint256 nonce)");

    /// @notice Domain separator for EIP-712 signatures
    bytes32 public immutable DOMAIN_SEPARATOR;

    /**
     * @notice Initializes the sponsor contract
     * @dev Sets up the EIP-712 domain separator based on contract address and chain
     */
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

    /**
     * @notice Get gas spent by a specific address
     * @param sender The address to check gas usage for
     * @return Amount of gas used by the sender
     */
    function gasSpent(address sender) external view returns (uint256) {
        return _getSponsorStorage().gasSpent[sender];
    }

    /**
     * @notice Get the current nonce for a specific address
     * @param sender The address to check nonce for
     * @return Current nonce value for the sender
     */
    function nonces(address sender) external view returns (uint256) {
        return _getSponsorStorage().nonces[sender];
    }

    /**
     * @notice Execute a transfer on behalf of a user who provided a valid signature
     * @dev Verifies EIP-712 signature, transfers ETH, and records gas usage
     * @param sender The address that authorized the transfer
     * @param recipient The address to receive the ETH
     * @param amount The amount of ETH to transfer
     * @param nonce The unique nonce to prevent replay attacks
     * @param v Recovery byte of the sender's signature
     * @param r First 32 bytes of the sender's signature
     * @param s Second 32 bytes of the sender's signature
     */
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
        SponsorStorage storage sponsorStorage = _getSponsorStorage();

        // Ensure nonce is not reused
        if (nonce != sponsorStorage.nonces[sender]++) revert NonceAlreadyUsed();

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
        if (recovered != address(this) && recovered != sender) revert InvalidSignature();

        // Store initial gas for measurement
        uint256 startGas = gasleft();

        // Execute the transfer
        (bool success,) = recipient.call{ value: amount }("");
        if (!success) revert TransferFailed();

        // Calculate and record gas usage
        uint256 gasUsed = startGas - gasleft();
        sponsorStorage.gasSpent[sender] += gasUsed;

        emit SponsoredTransfer(sender, recipient, amount, gasUsed);
    }

    /**
     * @notice Emitted when a sponsored transfer is successfully executed
     * @param sender The original sender (EOA) who authorized the transfer
     * @param recipient The recipient who received the funds
     * @param amount The amount of ETH transferred
     * @param gasUsed The amount of gas consumed by the transaction
     */
    event SponsoredTransfer(address indexed sender, address indexed recipient, uint256 amount, uint256 gasUsed);
}
