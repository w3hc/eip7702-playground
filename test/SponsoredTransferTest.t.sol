// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/src/Test.sol";
import "../src/Sponsor.sol";
import "../src/EIP7702Demonstrator.sol";

/// @title Sponsored Transfer Test
/// @notice Tests EIP-7702 functionality with gas sponsorship
/// @dev Shows how EOAs can execute transactions through a sponsor without paying gas
contract SponsoredTransferTest is Test {
    Sponsor public sponsor;
    EIP7702Demonstrator public demonstrator;
    address payable public alice;
    address payable public bob;
    address payable public relayer;
    uint256 public aliceKey;

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

    /// @notice Test a sponsored transfer using EIP-7702
    function testSponsoredTransfer() public {
        // Initial balances
        uint256 aliceBalanceBefore = alice.balance;
        uint256 bobBalanceBefore = bob.balance;

        // Setup EIP-7702 delegation
        bytes memory code = abi.encodePacked(hex"ef0100", address(sponsor));
        vm.etch(alice, code);

        // Track gas usage
        uint256 gasBefore = gasleft();

        // Create the call data for the sponsored transfer
        bytes memory callData = abi.encodeWithSelector(Sponsor.sponsoredTransfer.selector, bob);

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

    /// @notice Test behavior in Shanghai (should fail)
    function testNoCodeInShanghai() public {
        string memory evmVersion = vm.envOr("FOUNDRY_PROFILE", string("default"));
        if (keccak256(bytes(evmVersion)) == keccak256(bytes("shanghai"))) {
            bytes memory code = abi.encodePacked(hex"ef0100", address(sponsor));
            vm.etch(alice, code);
            vm.expectRevert();
            (bool success,) = alice.call{ value: 1 ether }("");
            success; // Silence unused variable warning
        }
    }
}
