// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract SignatureUtils {
    modifier verifySignature(address signer, bytes32 hash, uint8 v, bytes32 r, bytes32 s) {
        require(ECDSA.recover(hash, v, r, s) == signer, "Invalid Signature");
        // require(SignatureChecker.isValidSignatureNow(signer, hash, signature), "Invalid Signature");
        _;
    }
}
