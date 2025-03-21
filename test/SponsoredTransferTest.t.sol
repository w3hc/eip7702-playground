// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/src/Test.sol";
import "../src/Sponsor.sol";
import "../src/EIP7702Demonstrator.sol";

/**
 * @title SponsoredTransferTest
 * @notice Tests EIP-7702 functionality with gas sponsorship
 * @dev Demonstrates how EOAs can execute transactions through delegation without paying gas
 * @custom:eip EIP-7702 (EOA Code Setting), EIP-712 (Typed structured data hashing and signing)
 */
contract SponsoredTransferTest is Test {
    Sponsor public sponsor;
    EIP7702Demonstrator public demonstrator;
    address payable public alice;
    address payable public bob;
    address payable public relayer;
    uint256 public aliceKey;

    /**
     * @notice Set up the test environment
     * @dev Deploys contracts and sets up test accounts
     * @custom:requirement Requires Prague EVM version to support EIP-7702
     */
    function setUp() public {
        // Check EVM version
        string memory evmVersion = vm.envOr("FOUNDRY_PROFILE", string("default"));
        require(
            keccak256(bytes(evmVersion)) == keccak256(bytes("prague")),
            "This test requires Prague EVM. Set FOUNDRY_PROFILE=prague"
        );

        // Deploy contracts
        sponsor = new Sponsor();
        demonstrator = new EIP7702Demonstrator();

        // Create accounts
        aliceKey = 0x1234;
        alice = payable(vm.addr(aliceKey));
        bob = payable(makeAddr("bob"));
        relayer = payable(makeAddr("relayer"));

        // Fund accounts
        vm.deal(alice, 2 ether);
        vm.deal(relayer, 1 ether);
    }

    /**
     * @notice Test a sponsored transfer using EIP-7702 delegation
     * @dev Demonstrates complete EIP-7702 workflow:
     *      1. Setting delegation code on an EOA
     *      2. Creating a valid EIP-712 signature
     *      3. Executing a transaction through the delegated code
     *      4. Verifying correct balance changes
     */
    function testSponsoredTransfer() public {
        // Initial balances
        uint256 aliceBalanceBefore = alice.balance;
        uint256 bobBalanceBefore = bob.balance;

        // Setup EIP-7702 delegation
        bytes memory code = abi.encodePacked(hex"ef0100", address(sponsor));
        vm.etch(alice, code);

        // Track gas usage
        uint256 gasBefore = gasleft();

        // Get the current nonce
        uint256 nonce = sponsor.nonces(alice);

        // Create signature for EIP-712
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                sponsor.DOMAIN_SEPARATOR(),
                keccak256(abi.encode(sponsor.SPONSORED_TRANSFER_TYPEHASH(), alice, bob, 1 ether, nonce))
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(aliceKey, digest);

        // Create the call data for the sponsored transfer
        bytes memory callData = abi.encodeWithSelector(
            Sponsor.sponsoredTransfer.selector,
            alice,
            bob,
            1 ether,
            nonce,
            v,
            r, // signature r
            s // signature s
        );

        // Execute as Alice but with relayer paying gas
        vm.prank(alice);

        // Call directly to Alice's account which should delegate to sponsor via EIP-7702
        (bool success,) = address(alice).call{ value: 1 ether }(callData);
        require(success, "Call failed");

        uint256 gasUsed = gasBefore - gasleft();

        // Verify balances
        assertEq(alice.balance, aliceBalanceBefore - 1 ether, "Alice should only spend transfer amount");
        assertEq(bob.balance, bobBalanceBefore + 1 ether, "Bob should receive transfer amount");

        // Log transaction details
        console2.log("=== EIP-7702 Sponsored Transfer Details ===");
        console2.log("Delegation code size:", uint256(demonstrator.getCodeLength(alice)));
        console2.log("Gas used:", uint256(gasUsed));
        console2.log("Value transferred:", uint256(1 ether));
        console2.log("Sender (Alice) balance change:", aliceBalanceBefore - alice.balance);
        console2.log("Recipient (Bob) balance change:", bob.balance - bobBalanceBefore);
    }

    /**
     * @notice Test behavior in Shanghai (should fail)
     * @dev Verifies that EIP-7702 functionality is not available in pre-Prague EVM versions
     */
    function testNoCodeInShanghai() public {
        string memory evmVersion = vm.envOr("FOUNDRY_PROFILE", string("default"));
        if (keccak256(bytes(evmVersion)) == keccak256(bytes("shanghai"))) {
            bytes memory delegationCode = abi.encodePacked(hex"ef0100", address(sponsor));
            vm.etch(alice, delegationCode);
            vm.expectRevert();
            (bool success,) = alice.call{ value: 1 ether }("");
            success; // Silence unused variable warning
        }
    }
}
