// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

contract SignatureTestUtils is Test {
    function sign(uint256 privateKey, bytes32 hash) public pure returns (bytes memory signature) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, hash);

        return abi.encodePacked(r, s, v);
    }
}
