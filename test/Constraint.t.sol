// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "openzeppelin-contracts/contracts/mocks/ERC20Mock.sol";

import "../src/Constraint.sol";

bytes constant PASSED_DATE_AS_BYTES = "\x00\x00\x01\x86\x74\x70\xd6\x67";

bytes constant NOT_YET_PASSED_DATA_AS_BYTES = "\x00\x00\x02\x03\x5c\x0e\xa0\xe0";

contract ConstraintTest is Test {
    uint256 public constant currentDate = 1676991391466;
    bytes public constant currentDateAsBytes = "\x00\x00\x01\x86\x74\x79\xe6\xea";

    uint256 internal user1PrivateKey;
    address internal user1;

    ERC20Mock erc20Contract;

    Constraint constraint;

    function setUp() public {
        vm.warp(currentDate);
        constraint = new Constraint();

        user1PrivateKey = 0xb0b;
        user1 = vm.addr(user1PrivateKey);

        erc20Contract = new ERC20Mock("Test", "tst", user1, 1000);
    }

    function testConstraintCurrentBlockTimestampLower() public {
        bytes memory constraints = bytes.concat(bytes.concat("\x00\x00", NOT_YET_PASSED_DATA_AS_BYTES));

        bytes memory characteristics = constraint.applyConstraint(msg.sender, constraints);

        assertEq(characteristics, "");
    }

    function testConstraintCurrentBlockTimestampLowerOrEqual() public {
        bytes memory constraints = bytes.concat(bytes.concat("\x00\x01", currentDateAsBytes));

        bytes memory characteristics = constraint.applyConstraint(msg.sender, constraints);

        assertEq(characteristics, "");
    }

    function testConstraintCurrentBlockTimestampGreater() public {
        bytes memory constraints = bytes.concat(bytes.concat("\x00\x03", PASSED_DATE_AS_BYTES));

        bytes memory characteristics = constraint.applyConstraint(msg.sender, constraints);

        assertEq(characteristics, "");
    }

    function testConstraintCurrentBlockTimestampGreaterOrEqual() public {
        bytes memory constraints = bytes.concat(bytes.concat("\x00\x03", currentDateAsBytes));

        bytes memory characteristics = constraint.applyConstraint(msg.sender, constraints);

        assertEq(characteristics, "");
    }

    function testInvalidConstraintCurrentBlockTimestampLower() public {
        bytes memory constraints = bytes.concat(bytes.concat("\x00\x00", PASSED_DATE_AS_BYTES));

        vm.expectRevert("Block timestamp needs to be lower");
        bytes memory characteristics = constraint.applyConstraint(msg.sender, constraints);

        assertEq(characteristics, "");
    }

    function testInvalidConstraintCurrentBlockTimestampLowerOrEqual() public {
        bytes memory constraints = bytes.concat(bytes.concat("\x00\x01", PASSED_DATE_AS_BYTES));

        vm.expectRevert("Block timestamp needs to be lower or equal");
        bytes memory characteristics = constraint.applyConstraint(msg.sender, constraints);

        assertEq(characteristics, "");
    }

    function testInvalidConstraintCurrentBlockTimestampGreater() public {
        bytes memory constraints = bytes.concat(bytes.concat("\x00\x02", NOT_YET_PASSED_DATA_AS_BYTES));

        vm.expectRevert("Block timestamp needs to be greater");
        bytes memory characteristics = constraint.applyConstraint(msg.sender, constraints);

        assertEq(characteristics, "");
    }

    function testInvalidConstraintCurrentBlockTimestampGreaterOrEqual() public {
        bytes memory constraints = bytes.concat(bytes.concat("\x00\x03", NOT_YET_PASSED_DATA_AS_BYTES));

        vm.expectRevert("Block timestamp needs to be greater or equal");
        bytes memory characteristics = constraint.applyConstraint(msg.sender, constraints);

        assertEq(characteristics, "");
    }

    //
    // function testConstraintHasERC20BalanceAbove0() public {
    //     bytes memory constraints = bytes.concat("\x02", bytes(abi.encodePacked(address(erc20Contract))));
    //
    //     console.logAddress(address(erc20Contract));
    //
    //     bytes memory characteristics = constraint.applyConstraint(user1, constraints);
    //
    //     assertEq(characteristics, "");
    // }
}
