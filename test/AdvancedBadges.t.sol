// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/AdvancedBadge.sol";
import "../src/AdvancedBadgeSigUtils.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract AdvancedBadgeTest is Test {
    event NewEvent(
        address indexed creator,
        bytes32 eventHash
    );

    AdvancedBadge public badge;

    uint256 internal creatorPrivateKey;
    address internal creator;

    function setUp() public {
        badge = new AdvancedBadge("AdvancedBadge", "BDG");

        creatorPrivateKey = 0xabc;

        creator = vm.addr(creatorPrivateKey);
    }

    function testCreateEvent() public {
        Event memory _event = Event(creator, "");

        bytes32 digest = badge.getTypedDataHash(_event);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(creatorPrivateKey, digest);

        vm.expectEmit(true, true, false, false);

        emit NewEvent(creator, "");

        bytes32 eventHash = badge.createEvent(
            _event,
            v,
            r,
            s
        );

        (address creatorAddr, bytes memory mintingConstraints) = badge.eventsByHash(eventHash);
        assertEq(_event.creator, creatorAddr);
        assertEq(_event.mintingConstraints, mintingConstraints);
    }


    function testCreateAlreadyExistingEvent() public {
        Event memory _event = Event(creator, "");

        bytes32 digest = badge.getTypedDataHash(_event);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(creatorPrivateKey, digest);
        bytes32 eventHash = badge.createEvent(
            _event,
            v,
            r,
            s
        );


        vm.expectRevert("Event already exists");
        eventHash = badge.createEvent(
            _event,
            v,
            r,
            s
        );
    }

}
