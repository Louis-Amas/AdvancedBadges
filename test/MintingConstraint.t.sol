// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/MintingConstraint.sol";

bytes constant PASSED_DATE_AS_BYTES = "\x00\x00\x01\x86\x74\x70\xd6\x67";

bytes constant NOT_YET_PASSED_DATA_AS_BYTES = "\x00\x00\x02\x03\x5c\x0e\xa0\xe0";

contract MintingConstraintTest is Test {
    uint256 public constant currentDate = 1676991391466;

    MintingConstraint mintingConstraint;

    function setUp() public {
        vm.warp(currentDate);
        mintingConstraint = new MintingConstraint();
    }

    function testCanMintCurrentDateAboveConstraint() public {
        bytes memory constraints = bytes.concat(bytes.concat("\x00", PASSED_DATE_AS_BYTES));

        bytes memory characteristics = mintingConstraint.canMint(msg.sender, constraints);

        assertEq(characteristics, "");
    }

    function testCanMintCurrentDateBelownConstraint() public {
        bytes memory constraints = bytes.concat(bytes.concat("\x01", NOT_YET_PASSED_DATA_AS_BYTES));

        bytes memory characteristics = mintingConstraint.canMint(msg.sender, constraints);

        assertEq(characteristics, "");
    }

    function testCantMintCurrentDateAboveConstraint() public {
        bytes memory constraints = bytes.concat(bytes.concat("\x00", NOT_YET_PASSED_DATA_AS_BYTES));

        vm.expectRevert("Block timestamp constraint is greater than required");
        bytes memory characteristics = mintingConstraint.canMint(msg.sender, constraints);

        assertEq(characteristics, "");
    }

    function testCantMintCurrentDateBelownConstraint() public {
        bytes memory constraints = bytes.concat(bytes.concat("\x01", PASSED_DATE_AS_BYTES));

        vm.expectRevert("Block timestamp constraint is lower than required");
        bytes memory characteristics = mintingConstraint.canMint(msg.sender, constraints);

        assertEq(characteristics, "");
    }

    function testCanMintCombineBelowAndAboveConstraint() public {
        bytes memory constraints =
            bytes.concat(bytes.concat("\x00", PASSED_DATE_AS_BYTES), bytes.concat("\x01", NOT_YET_PASSED_DATA_AS_BYTES));

        bytes memory characteristics = mintingConstraint.canMint(msg.sender, constraints);

        assertEq(characteristics, "");
    }

    function testCanMintCombineFailedBelowAndAboveConstraint() public {
        bytes memory constraints = bytes.concat(bytes.concat("\x00", PASSED_DATE_AS_BYTES), bytes.concat("\x01", PASSED_DATE_AS_BYTES));

        vm.expectRevert("Block timestamp constraint is lower than required");
        bytes memory characteristics = mintingConstraint.canMint(msg.sender, constraints);

        assertEq(characteristics, "");
    }

    function testCanMintCombineBelowAndFailedAboveConstraint() public {
        bytes memory constraints =
            bytes.concat(bytes.concat("\x00", NOT_YET_PASSED_DATA_AS_BYTES), bytes.concat("\x01", NOT_YET_PASSED_DATA_AS_BYTES));

        vm.expectRevert("Block timestamp constraint is greater than required");
        bytes memory characteristics = mintingConstraint.canMint(msg.sender, constraints);

        assertEq(characteristics, "");
    }
}
