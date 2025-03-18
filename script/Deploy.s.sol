// SPDX-License-Identifier: MIT
pragma solidity >=0.8.28 <0.9.0;

import { EIP7702Demonstrator } from "../src/EIP7702Demonstrator.sol";
import { EIP7702Test } from "../src/EIP7702Test.sol";
import { Sponsor } from "../src/Sponsor.sol";
import { BaseScript } from "./Base.s.sol";
import { console2 } from "forge-std/src/console2.sol";

/**
 * @title Deploy
 * @notice Deployment script for EIP-7702 demonstration contracts
 * @dev Handles deployment and initial setup of all contracts needed for EIP-7702 demos
 * @custom:eip EIP-7702 (EOA Code Setting)
 */
contract Deploy is BaseScript {
    /**
     * @notice Deploy and set up all EIP-7702 demonstration contracts
     * @dev Checks for Prague EVM support, deploys contracts, and creates a test authorization
     * @return demonstrator The deployed EIP7702Demonstrator contract
     * @return test The deployed EIP7702Test helper contract
     * @return sponsor The deployed Sponsor contract
     */
    function run() public broadcast returns (EIP7702Demonstrator demonstrator, EIP7702Test test, Sponsor sponsor) {
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

        // Deploy the sponsor contract
        sponsor = new Sponsor();
        console2.log("Sponsor deployed at:", address(sponsor));

        // Verify deployments were successful
        require(address(demonstrator) != address(0), "Demonstrator deployment failed");
        require(address(test) != address(0), "Test deployment failed");
        require(address(sponsor) != address(0), "Sponsor deployment failed");

        // Verify contracts have the expected code
        uint256 demonstratorSize;
        uint256 testSize;
        uint256 sponsorSize;
        assembly {
            demonstratorSize := extcodesize(demonstrator)
            testSize := extcodesize(test)
            sponsorSize := extcodesize(sponsor)
        }
        require(demonstratorSize > 0, "Demonstrator has no code");
        require(testSize > 0, "Test helper has no code");
        require(sponsorSize > 0, "Sponsor has no code");

        // Create a test authorization for the sponsor contract
        try test.createAuthorization(
            block.chainid,
            address(sponsor), // Using sponsor as the authorized contract
            0 // nonce
        ) returns (bytes memory auth) {
            console2.log("Successfully created test authorization for sponsor");

            // Log the authorization details
            console2.log("Authorization length:", auth.length);
            console2.log("Target contract:", address(sponsor));

            // Create the delegation designator that would be used
            bytes memory delegationDesignator = abi.encodePacked(hex"ef0100", address(sponsor));
            console2.log("Delegation designator length:", delegationDesignator.length);
        } catch Error(string memory reason) {
            console2.log("Failed to create authorization:", reason);
        }

        console2.log("Deployment completed successfully");
    }
}
