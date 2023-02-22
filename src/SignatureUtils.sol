// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/SignatureChecker.sol";

contract SignatureUtils {


    modifier verifySignature(address signer, bytes32 hash, bytes calldata signature) {
        require(SignatureChecker.isValidSignatureNow(signer, hash, signature), "Invalid Signature");
        _;
    }
}
