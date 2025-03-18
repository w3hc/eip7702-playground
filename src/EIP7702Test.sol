// SPDX-License-Identifier: MIT
pragma solidity >=0.8.28;

/**
 * @title EIP7702Test
 * @notice Helper contract for testing EIP-7702 authorizations
 * @dev Creates properly formatted EIP-7702 authorizations for testing purposes
 * @custom:eip EIP-7702 (EOA Code Setting)
 */
contract EIP7702Test {
    /**
     * @notice Emitted when a new authorization is created
     * @param signer The address that signed the authorization
     * @param codeAddress The contract address being authorized
     * @param nonce The nonce used for this authorization
     */
    event Authorization(address indexed signer, address indexed codeAddress, uint64 nonce);

    /// @dev Magic bytes for EIP-7702 transaction type
    bytes4 public constant EIP7702_TX_TYPE = bytes4(hex"04000000");

    /**
     * @notice Creates an EIP-7702 compliant authorization
     * @dev Constructs the authorization digest with EIP-7702 magic byte (0x05)
     * @param chainId The chain ID where this authorization is valid
     * @param codeAddress The target contract address being authorized
     * @param nonce The nonce to prevent replay attacks
     * @return The encoded authorization data for EIP-7702
     */
    function createAuthorization(uint256 chainId, address codeAddress, uint64 nonce) public returns (bytes memory) {
        // Create the authorization digest with EIP-7702 magic byte
        bytes32 digest = keccak256(
            abi.encodePacked(
                bytes1(hex"05"), // EIP-7702 magic byte
                abi.encode(chainId, codeAddress, nonce)
            )
        );

        emit Authorization(msg.sender, codeAddress, nonce);

        // Return the EIP-7702 transaction payload
        return abi.encode(chainId, nonce, codeAddress, digest);
    }
}
