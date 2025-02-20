// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/src/Test.sol";
import "../src/Sponsor.sol";

contract SponsorTest is Test {
    Sponsor public sponsor;
    address payable public alice;
    address payable public bob;

    function setUp() public {
        // Deploy the sponsor contract
        sponsor = new Sponsor();

        // Create accounts for Alice and Bob
        alice = payable(makeAddr("alice"));
        bob = payable(makeAddr("bob"));

        // Fund Alice with some ETH
        vm.deal(alice, 2 ether);
    }

    // Basic functionality test - no EIP-7702 features
    function testBasicSponsorFunctionality() public {
        vm.prank(alice);
        sponsor.sponsoredTransfer{ value: 1 ether }(bob);
        assertEq(bob.balance, 1 ether);
    }
}
