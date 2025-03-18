// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/src/Test.sol";
import "../src/Sponsor.sol";

/**
 * @title SponsorTest
 * @notice Test contract for basic Sponsor contract functionality without EIP-7702
 * @dev Tests standard EIP-712 signature verification and execution in the Sponsor contract
 */
contract SponsorTest is Test {
    Sponsor public sponsor;
    address payable public alice;
    address payable public bob;

    /**
     * @notice Set up the test environment
     * @dev Deploys the Sponsor contract and sets up test accounts
     */
    function setUp() public {
        // Deploy the sponsor contract
        sponsor = new Sponsor();

        // Create accounts for Alice and Bob
        alice = payable(makeAddr("alice"));
        bob = payable(makeAddr("bob"));

        // Fund Alice with some ETH
        vm.deal(alice, 2 ether);
    }

    /**
     * @notice Tests basic sponsorship functionality without EIP-7702
     * @dev Verifies that the Sponsor contract can execute transactions with valid EIP-712 signatures
     */
    function testBasicSponsorFunctionality() public {
        // Create a private key and derive the address
        uint256 alicePrivateKey = 0xA11CE;
        address derivedAliceAddress = vm.addr(alicePrivateKey);

        // Replace alice with the derived address
        alice = payable(derivedAliceAddress);
        vm.deal(alice, 2 ether); // Fund the correct address

        // Get the current nonce
        uint256 nonce = sponsor.nonces(alice);

        // Create signature digest using EIP-712
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                sponsor.DOMAIN_SEPARATOR(),
                keccak256(abi.encode(sponsor.SPONSORED_TRANSFER_TYPEHASH(), alice, bob, 1 ether, nonce))
            )
        );

        // Sign the message
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, digest);

        // Execute the sponsored transfer
        sponsor.sponsoredTransfer{ value: 1 ether }(alice, bob, 1 ether, nonce, v, r, s);

        // Verify Bob received the ether
        assertEq(bob.balance, 1 ether, "Bob should have received 1 ether");
    }
}
