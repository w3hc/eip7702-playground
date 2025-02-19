// SPDX-License-Identifier: MIT
pragma solidity >=0.8.28;

/// @title EIP7702Test
/// @notice Helper contract for testing EIP-7702 functionality
contract EIP7702Test {
    event Authorization(address indexed signer, address indexed codeAddress, uint64 nonce);

    // Transaction type for EIP-7702
    bytes4 constant EIP7702_TX_TYPE = bytes4(hex"04000000"); // Properly formatted as bytes4

    /// @notice Creates an EIP-7702 authorization
    /// @param chainId The chain ID for the authorization
    /// @param codeAddress The address of the code to execute
    /// @param nonce The nonce for the authorization
    /// @return The encoded authorization data
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
