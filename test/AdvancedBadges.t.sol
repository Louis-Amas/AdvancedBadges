// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

import "../src/Constraint.sol";
import "../src/AdvancedBadge.sol";
import "./Constraint.t.sol";
import "./SignatureUtils.t.sol";

contract AdvancedBadgeTest is SignatureTestUtils {
    event NewEvent(address indexed creator, bytes32 eventHash);

    uint256 private constant currentDate = 1676991391466;

    bytes public validBlockTimestampGreaterConstraint = bytes.concat("\x00\x02", PASSED_DATE_AS_BYTES);

    bytes public validBlockTimestampLowerConstraint = bytes.concat("\x00\x00", NOT_YET_PASSED_DATA_AS_BYTES);

    AdvancedBadge public badge;
    Constraint public ConstraintContract;

    uint256 internal creatorPrivateKey;
    address internal creator;

    uint256 internal user1PrivateKey;
    address internal user1;

    uint256 internal user2PrivateKey;
    address internal user2;

    function setUp() public {
        vm.warp(currentDate);

        ConstraintContract = new Constraint();
        badge = new AdvancedBadge(address(ConstraintContract), "AdvancedBadge", "BDG");

        creatorPrivateKey = 0xabc;
        creator = vm.addr(creatorPrivateKey);

        user1PrivateKey = 0xb0b;
        user1 = vm.addr(user1PrivateKey);

        user2PrivateKey = 0xaaa;
        user2 = vm.addr(user2PrivateKey);
    }

    function testCreateEvent() public {
        AdvancedBadge.Event memory eventStruct = AdvancedBadge.Event(creator, "");

        vm.expectEmit(true, true, false, false);

        emit NewEvent(creator, "");

        vm.prank(creator);
        bytes32 eventHash = badge.createEvent(eventStruct);

        (address creatorAddr, bytes memory Constraints) = badge.eventsByHash(eventHash);
        assertEq(eventStruct.creator, creatorAddr);
        assertEq(eventStruct.Constraints, Constraints);
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
            bytes.concat(validBlockTimestampGreaterConstraint, validBlockTimestampLowerConstraint);

        AdvancedBadge.Event memory eventStruct = AdvancedBadge.Event(creator, validConstraints);

        vm.prank(creator);
        bytes32 eventHash = badge.createEvent(eventStruct);

        vm.prank(user1);
        badge.mintBadge(user1, eventHash);

        assertEq(badge.ownerOf(0), user1);
    }

    function testInvalidMintBadge() public {
        bytes memory validConstraints =
            bytes.concat(validBlockTimestampGreaterConstraint, validBlockTimestampLowerConstraint);

        AdvancedBadge.Event memory eventStruct = AdvancedBadge.Event(creator, validConstraints);

        vm.prank(creator);
        bytes32 eventHash = badge.createEvent(eventStruct);

        vm.expectRevert("Only sender can mint badge");
        badge.mintBadge(user1, eventHash);
    }

    function testValidMintBadgeWithSignature() public {
        bytes memory validConstraints =
            bytes.concat(validBlockTimestampGreaterConstraint, validBlockTimestampLowerConstraint);

        AdvancedBadge.Event memory eventStruct = AdvancedBadge.Event(creator, validConstraints);

        vm.prank(creator);
        badge.createEvent(eventStruct);

        ( /*bytes32 eventHash*/ , bytes32 typedEventHash) = badge.getTypedDataHash(eventStruct);

        bytes memory signature = sign(user1PrivateKey, typedEventHash);

        badge.mintBadgeWithSignature(user1, eventStruct, signature);

        assertEq(badge.ownerOf(0), user1);
    }

    function testValidMintBadgeWithSignatureUser2() public {
        bytes memory validConstraints =
            bytes.concat(validBlockTimestampGreaterConstraint, validBlockTimestampLowerConstraint);

        AdvancedBadge.Event memory eventStruct = AdvancedBadge.Event(creator, validConstraints);

        vm.prank(creator);
        badge.createEvent(eventStruct);

        ( /*bytes32 eventHash*/ , bytes32 typedEventHash) = badge.getTypedDataHash(eventStruct);

        bytes memory signature = sign(user2PrivateKey, typedEventHash);
        badge.mintBadgeWithSignature(user2, eventStruct, signature);

        assertEq(badge.ownerOf(0), user2);
    }

    function testInvalidMintBadgeWithSignature() public {
        bytes memory validConstraints =
            bytes.concat(validBlockTimestampGreaterConstraint, validBlockTimestampLowerConstraint);

        AdvancedBadge.Event memory eventStruct = AdvancedBadge.Event(creator, validConstraints);

        vm.prank(creator);
        badge.createEvent(eventStruct);

        ( /*bytes32 eventHash*/ , bytes32 typedEventHash) = badge.getTypedDataHash(eventStruct);

        bytes memory signature = sign(user2PrivateKey, typedEventHash); // use the wwrong private key

        vm.expectRevert("Invalid Signature");
        badge.mintBadgeWithSignature(user1, eventStruct, signature);
    }

    function testValidBatchMintBadges() public {
        bytes memory validConstraints =
            bytes.concat(validBlockTimestampGreaterConstraint, validBlockTimestampLowerConstraint);

        AdvancedBadge.Event memory eventStruct = AdvancedBadge.Event(creator, validConstraints);

        vm.prank(creator);
        badge.createEvent(eventStruct);

        ( /*bytes32 eventHash*/ , bytes32 typedEventHash) = badge.getTypedDataHash(eventStruct);

        bytes memory signature1 = sign(user1PrivateKey, typedEventHash);
        bytes memory signature2 = sign(user2PrivateKey, typedEventHash);

        AdvancedBadge.Parameters[] memory params = new AdvancedBadge.Parameters[](2);
        params[0] = AdvancedBadge.Parameters(user1, eventStruct, signature1);
        params[1] = AdvancedBadge.Parameters(user2, eventStruct, signature2);

        badge.batchMintBadges(params);

        assertEq(badge.ownerOf(0), user1);
        assertEq(badge.ownerOf(1), user2);
    }
}
