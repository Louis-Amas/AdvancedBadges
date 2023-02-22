// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/SignatureChecker.sol";

import "./SignatureUtils.t.sol";

contract SignatureTest is SignatureTestUtils {
    uint256 internal creatorPrivateKey;
    address internal creator;

    function setUp() public {
        creatorPrivateKey = 0xabc;
        creator = vm.addr(creatorPrivateKey);
    }

    function testSignature() public {
        bytes32 hash = keccak256("Test...");

        bytes memory signature = SignatureTestUtils.sign(creatorPrivateKey, hash);

        bool isValid = SignatureChecker.isValidSignatureNow(creator, hash, signature);

        assertEq(isValid, true);
    }
}
