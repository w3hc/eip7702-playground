// SPDX-License-Identifier: MIT
pragma solidity >=0.8.28 <0.9.0;

import { EIP7702Demonstrator } from "../src/EIP7702Demonstrator.sol";
import { EIP7702Test } from "../src/EIP7702Test.sol";
import { BaseScript } from "./Base.s.sol";
import { console2 } from "forge-std/src/console2.sol";

/// @dev Deployment script for EIP-7702 demonstration contracts
contract Deploy is BaseScript {
    function run() public broadcast returns (EIP7702Demonstrator demonstrator, EIP7702Test test) {
        // Check EVM version supports EIP-7702
        string memory evmVersion = vm.envOr("FOUNDRY_PROFILE", string("default"));
        require(
            keccak256(bytes(evmVersion)) == keccak256(bytes("prague")),
            "EIP-7702 requires Prague EVM. Set FOUNDRY_PROFILE=prague"
        );

        // Deploy the demonstrator contract
        demonstrator = new EIP7702Demonstrator();
        console2.log("EIP7702Demonstrator deployed at:", address(demonstrator));

        // Deploy the test helper contract
        test = new EIP7702Test();
        console2.log("EIP7702Test deployed at:", address(test));

        // Verify deployment was successful
        require(address(demonstrator) != address(0), "Demonstrator deployment failed");
        require(address(test) != address(0), "Test deployment failed");

        // Verify contracts have the expected code
        uint256 demonstratorSize;
        uint256 testSize;
        assembly {
            demonstratorSize := extcodesize(demonstrator)
            testSize := extcodesize(test)
        }
        require(demonstratorSize > 0, "Demonstrator has no code");
        require(testSize > 0, "Test helper has no code");

        // Create a test authorization to verify EIP-7702 functionality
        try test.createAuthorization(
            block.chainid,
            address(demonstrator),
            0 // nonce
        ) returns (bytes memory auth) {
            console2.log("Successfully created test authorization");
        } catch Error(string memory reason) {
            console2.log("Failed to create authorization:", reason);
        }

        console2.log("Deployment completed successfully");
    }
}
