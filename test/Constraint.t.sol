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

    function testCanMintCurrentDateAboveConstraint() public {
        bytes memory constraints = bytes.concat(bytes.concat("\x00", PASSED_DATE_AS_BYTES));

        bytes memory characteristics = constraint.applyConstraint(msg.sender, constraints);

        assertEq(characteristics, "");
    }

    function testCanMintCurrentDateBelownConstraint() public {
        bytes memory constraints = bytes.concat(bytes.concat("\x01", NOT_YET_PASSED_DATA_AS_BYTES));

        bytes memory characteristics = constraint.applyConstraint(msg.sender, constraints);

        assertEq(characteristics, "");
    }

    function testCantMintCurrentDateAboveConstraint() public {
        bytes memory constraints = bytes.concat(bytes.concat("\x00", NOT_YET_PASSED_DATA_AS_BYTES));

        vm.expectRevert("Block timestamp constraint is greater than required");
        bytes memory characteristics = constraint.applyConstraint(msg.sender, constraints);

        assertEq(characteristics, "");
    }

    function testCantMintCurrentDateBelownConstraint() public {
        bytes memory constraints = bytes.concat(bytes.concat("\x01", PASSED_DATE_AS_BYTES));

        vm.expectRevert("Block timestamp constraint is lower than required");
        bytes memory characteristics = constraint.applyConstraint(msg.sender, constraints);

        assertEq(characteristics, "");
    }

    function testCanMintCombineBelowAndAboveConstraint() public {
        bytes memory constraints =
            bytes.concat(bytes.concat("\x00", PASSED_DATE_AS_BYTES), bytes.concat("\x01", NOT_YET_PASSED_DATA_AS_BYTES));

        bytes memory characteristics = constraint.applyConstraint(msg.sender, constraints);

        assertEq(characteristics, "");
    }

    function testCanMintCombineFailedBelowAndAboveConstraint() public {
        bytes memory constraints =
            bytes.concat(bytes.concat("\x00", PASSED_DATE_AS_BYTES), bytes.concat("\x01", PASSED_DATE_AS_BYTES));

        vm.expectRevert("Block timestamp constraint is lower than required");
        bytes memory characteristics = constraint.applyConstraint(msg.sender, constraints);

        assertEq(characteristics, "");
    }

    function testCanMintCombineBelowAndFailedAboveConstraint() public {
        bytes memory constraints = bytes.concat(
            bytes.concat("\x00", NOT_YET_PASSED_DATA_AS_BYTES), bytes.concat("\x01", NOT_YET_PASSED_DATA_AS_BYTES)
        );

        vm.expectRevert("Block timestamp constraint is greater than required");
        bytes memory characteristics = constraint.applyConstraint(msg.sender, constraints);

        assertEq(characteristics, "");
    }

    function testCanMintHasERC20BalanceAbove0() public {
        bytes memory constraints = bytes.concat("\x02", bytes(abi.encodePacked(address(erc20Contract))));

        console.logAddress(address(erc20Contract));

        bytes memory characteristics = constraint.applyConstraint(user1, constraints);

        assertEq(characteristics, "");
    }
}
