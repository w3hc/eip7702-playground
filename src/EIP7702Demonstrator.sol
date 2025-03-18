// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title EIP7702Demonstrator
 * @notice Utility contract for demonstrating and testing EIP-7702 functionality
 * @dev Provides functions to inspect EOA code properties with EIP-7702 delegation
 * @custom:eip EIP-7702 (EOA Code Setting)
 */
contract EIP7702Demonstrator {
    /**
     * @notice Get the code size of any account
     * @dev Uses assembly to directly access the extcodesize opcode
     * @param account The address to check code size for
     * @return The size of the code at the given address in bytes
     */
    function getCodeLength(address account) external view returns (uint256) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size;
    }
}
