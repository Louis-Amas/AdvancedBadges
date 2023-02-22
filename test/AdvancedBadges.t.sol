// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

import "../src/MintingConstraint.sol";
import "../src/AdvancedBadge.sol";
import "./MintingConstraint.t.sol";
import "./SignatureUtils.t.sol";

contract AdvancedBadgeTest is SignatureTestUtils {
    event NewEvent(address indexed creator, bytes32 eventHash);

    uint256 private constant currentDate = 1676991391466;

    bytes public validBlockTimestampAboveConstraint = bytes.concat("\x00", PASSED_DATE_AS_BYTES);

    bytes public validBlockTimestampBelowConstraint = bytes.concat("\x01", NOT_YET_PASSED_DATA_AS_BYTES);

    AdvancedBadge public badge;
    MintingConstraint public mintingConstraintContract;

    uint256 internal creatorPrivateKey;
    address internal creator;

    uint256 internal userPrivateKey;
    address internal user;

    function setUp() public {
        vm.warp(currentDate);

        mintingConstraintContract = new MintingConstraint();
        badge = new AdvancedBadge(address(mintingConstraintContract), "AdvancedBadge", "BDG");

        creatorPrivateKey = 0xabc;
        creator = vm.addr(creatorPrivateKey);

        userPrivateKey = 0xb0b;
        user = vm.addr(userPrivateKey);
    }

    function testCreateEvent() public {
        AdvancedBadge.Event memory eventStruct = AdvancedBadge.Event(creator, "");

        vm.expectEmit(true, true, false, false);

        emit NewEvent(creator, "");

        vm.prank(creator);
        bytes32 eventHash = badge.createEvent(eventStruct);

        (address creatorAddr, bytes memory mintingConstraints) = badge.eventsByHash(eventHash);
        assertEq(eventStruct.creator, creatorAddr);
        assertEq(eventStruct.mintingConstraints, mintingConstraints);
    }

    function testCreateAlreadyExistingEvent() public {
        AdvancedBadge.Event memory eventStruct = AdvancedBadge.Event(creator, "");

        vm.prank(creator);
        bytes32 eventHash = badge.createEvent(eventStruct);

        vm.expectRevert("Event already exists");
        eventHash = badge.createEvent(eventStruct);
    }

    function testValidMintBadge() public {
        bytes memory validConstraints =
            bytes.concat(validBlockTimestampAboveConstraint, validBlockTimestampBelowConstraint);

        AdvancedBadge.Event memory eventStruct = AdvancedBadge.Event(creator, validConstraints);

        vm.prank(creator);
        bytes32 eventHash = badge.createEvent(eventStruct);

        vm.prank(user);
        badge.mintBadge(user, eventHash);

        assertEq(badge.ownerOf(0), user);
    }

    function testInvalidMintBadge() public {
        bytes memory validConstraints =
            bytes.concat(validBlockTimestampAboveConstraint, validBlockTimestampBelowConstraint);

        AdvancedBadge.Event memory eventStruct = AdvancedBadge.Event(creator, validConstraints);

        vm.prank(creator);
        bytes32 eventHash = badge.createEvent(eventStruct);

        vm.expectRevert("Only sender can mint badge");
        badge.mintBadge(user, eventHash);
    }

    function testValidMintBadgeWithSignature() public {
        bytes memory validConstraints =
            bytes.concat(validBlockTimestampAboveConstraint, validBlockTimestampBelowConstraint);

        AdvancedBadge.Event memory eventStruct = AdvancedBadge.Event(creator, validConstraints);

        vm.prank(creator);
        bytes32 eventHash = badge.createEvent(eventStruct);

        ( /*bytes32 eventHash*/ , bytes32 typedEventHash) = badge.getTypedDataHash(eventStruct);

        bytes memory signature = sign(userPrivateKey, typedEventHash);
        badge.mintBadgeWithSignature(user, eventStruct, signature);

        assertEq(badge.ownerOf(0), user);
    }

    function testInvalidMintBadgeWithSignature() public {
        bytes memory validConstraints =
            bytes.concat(validBlockTimestampAboveConstraint, validBlockTimestampBelowConstraint);

        AdvancedBadge.Event memory eventStruct = AdvancedBadge.Event(creator, validConstraints);

        vm.prank(creator);
        bytes32 eventHash = badge.createEvent(eventStruct);

        ( /*bytes32 eventHash*/ , bytes32 typedEventHash) = badge.getTypedDataHash(eventStruct);

        bytes memory signature = sign(creatorPrivateKey, typedEventHash); // use the wrong pirvate key

        vm.expectRevert("Invalid Signature");
        badge.mintBadgeWithSignature(user, eventStruct, signature);
    }
}
