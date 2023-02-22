// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/AdvancedBadge.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract AdvancedBadgeTest is Test {
    event NewEvent(address indexed creator, bytes32 eventHash);

    AdvancedBadge public badge;

    uint256 internal creatorPrivateKey;
    address internal creator;

    function setUp() public {
        badge = new AdvancedBadge("AdvancedBadge", "BDG");

        creatorPrivateKey = 0xabc;
        creator = vm.addr(creatorPrivateKey);
    }

    function testCreateEvent() public {
        AdvancedBadge.Event memory _event = AdvancedBadge.Event(creator, "");

        vm.expectEmit(true, true, false, false);

        emit NewEvent(creator, "");

        vm.prank(creator);
        bytes32 eventHash = badge.createEvent(_event);

        (address creatorAddr, bytes memory mintingConstraints) = badge.eventsByHash(eventHash);
        assertEq(_event.creator, creatorAddr);
        assertEq(_event.mintingConstraints, mintingConstraints);
    }

    function testCreateAlreadyExistingEvent() public {
        AdvancedBadge.Event memory _event = AdvancedBadge.Event(creator, "");

        vm.prank(creator);
        bytes32 eventHash = badge.createEvent(_event);

        vm.expectRevert("Event already exists");
        eventHash = badge.createEvent(_event);
    }
}
