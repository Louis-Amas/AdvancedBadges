// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/MintingConstraint.sol";

contract SignatureTest is Test {
    bytes private constant passedDate = "\x00\x00\x01\x86\x74\x70\xd6\x67";
    bytes private constant notYetPassedDate = "\x00\x00\x02\x03\x5c\x0e\xa0\xe0";
    uint256 private constant currentDate = 1676991391466;

    MintingConstraint mintingConstraint;

    function setUp() public {
        mintingConstraint = new MintingConstraint();
        vm.warp(1676991391466);
    }

    function testCanMintCurrentDateAboveConstraint() public {
        bytes memory constraints = bytes.concat(bytes.concat("\x00", passedDate));

        bytes memory characteristics = mintingConstraint.canMint(msg.sender, constraints);

        assertEq(characteristics, "");
    }

    function testCanMintCurrentDateBelownConstraint() public {
        bytes memory constraints = bytes.concat(bytes.concat("\x01", notYetPassedDate));

        bytes memory characteristics = mintingConstraint.canMint(msg.sender, constraints);

        assertEq(characteristics, "");
    }

    function testCantMintCurrentDateAboveConstraint() public {
        bytes memory constraints = bytes.concat(bytes.concat("\x00", notYetPassedDate));

        vm.expectRevert("Block timestamp constraint is greater than required");
        bytes memory characteristics = mintingConstraint.canMint(msg.sender, constraints);

        assertEq(characteristics, "");
    }

    function testCantMintCurrentDateBelownConstraint() public {
        bytes memory constraints = bytes.concat(bytes.concat("\x01", passedDate));

        vm.expectRevert("Block timestamp constraint is lower than required");
        bytes memory characteristics = mintingConstraint.canMint(msg.sender, constraints);

        assertEq(characteristics, "");
    }

    function testCanMintCombineBelowAndAboveConstraint() public {
        bytes memory constraints =
            bytes.concat(bytes.concat("\x00", passedDate), bytes.concat("\x01", notYetPassedDate));

        bytes memory characteristics = mintingConstraint.canMint(msg.sender, constraints);

        assertEq(characteristics, "");
    }

    function testCanMintCombineFailedBelowAndAboveConstraint() public {
        bytes memory constraints = bytes.concat(bytes.concat("\x00", passedDate), bytes.concat("\x01", passedDate));

        vm.expectRevert("Block timestamp constraint is lower than required");
        bytes memory characteristics = mintingConstraint.canMint(msg.sender, constraints);

        assertEq(characteristics, "");
    }

    function testCanMintCombineBelowAndFailedAboveConstraint() public {
        bytes memory constraints =
            bytes.concat(bytes.concat("\x00", notYetPassedDate), bytes.concat("\x01", notYetPassedDate));

        vm.expectRevert("Block timestamp constraint is greater than required");
        bytes memory characteristics = mintingConstraint.canMint(msg.sender, constraints);

        assertEq(characteristics, "");
    }
}
