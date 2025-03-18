// SPDX-License-Identifier: MIT
pragma solidity >=0.8.28;

import "forge-std/src/Test.sol";
import "../src/EIP7702Demonstrator.sol";
import "../src/EIP7702Test.sol";

/**
 * @title EIP7702SupportTest
 * @notice Test contract verifying EIP-7702 functionality across different EVM versions
 * @dev Tests whether EOA code setting works as expected in different EVM versions (Prague vs Shanghai)
 * @custom:eip EIP-7702 (EOA Code Setting)
 */
contract EIP7702SupportTest is Test {
    EIP7702Demonstrator public demonstrator;
    EIP7702Test public testHelper;

    /**
     * @notice Emitted when code is executed on an EOA through delegation
     * @param origin The original transaction sender
     * @param caller The address calling the code
     */
    event CodeExecuted(address origin, address caller);

    /**
     * @notice Set up the test environment
     * @dev Deploys the necessary contracts for testing
     */
    function setUp() public {
        demonstrator = new EIP7702Demonstrator();
        testHelper = new EIP7702Test();
    }

    /**
     * @notice Tests EIP-7702 support in different EVM versions
     * @dev Checks if code can be set on an EOA in Prague (should work) vs Shanghai (should fail)
     */
    function testEVMVersionSupport() public {
        string memory evmVersion = vm.envString("FOUNDRY_PROFILE");
        address eoa = makeAddr("testEOA");

        if (keccak256(bytes(evmVersion)) == keccak256(bytes("prague"))) {
            // In Prague, setting delegation code on EOA should work
            bytes memory delegationCode = abi.encodePacked(
                hex"ef0100", // EIP-7702 delegation designation
                address(demonstrator)
            );

            // Try to set code on EOA
            vm.etch(eoa, delegationCode);

            // Verify code was set correctly
            bytes memory code = address(eoa).code;
            assertEq(code, delegationCode, "Delegation code wasn't set correctly on EOA in Prague");

            // Verify code size
            uint256 size;
            assembly {
                size := extcodesize(eoa)
            }
            assertEq(size, 23, "EOA code size should be 23 bytes in Prague");
        } else if (keccak256(bytes(evmVersion)) == keccak256(bytes("shanghai"))) {
            // In Shanghai, setting code on EOA should revert
            bytes memory delegationCode = abi.encodePacked(
                hex"ef0100", // EIP-7702 delegation designation
                address(demonstrator)
            );

            vm.expectRevert();
            vm.etch(eoa, delegationCode);

            // Verify no code was set
            uint256 size;
            assembly {
                size := extcodesize(eoa)
            }
            assertEq(size, 0, "EOA should have no code in Shanghai");
        } else {
            revert("Unsupported EVM version");
        }
    }
}
