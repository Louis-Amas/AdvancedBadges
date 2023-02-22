// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/SignatureChecker.sol";

contract SignatureTest is Test {
    uint256 internal creatorPrivateKey;
    address internal creator;

    function setUp() public {
        creatorPrivateKey = 0xabc;
        creator = vm.addr(creatorPrivateKey);
    }

    function testSignature() public {
        bytes32 hash = keccak256("Test...");

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(creatorPrivateKey, hash);

        bytes memory joinSignature = bytes.concat(bytes.concat(r, s), "\x1b");

        bool isValid = SignatureChecker.isValidSignatureNow(creator, hash, joinSignature);

        assertEq(isValid, true);
    }
}
