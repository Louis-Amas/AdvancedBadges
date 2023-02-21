// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;
import "openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "forge-std/console.sol";

struct Event {
    address creator;
    bytes mintingConstraints;
}

contract AdvancedBadgeSigUtils is EIP712("AdvancedBadges", "1") {
    bytes32 constant public BADGE_TYPE_HASH = keccak256(
        "Event(address creator,bytes mintingConstraints)"
    );

    // computes the hash of a permit
    function getStructHash(Event memory _event)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    BADGE_TYPE_HASH,
                    _event.creator,
                    _event.mintingConstraints
                )
            );
    }

    // computes the hash of the fully encoded EIP-712 message for the domain, which can be used to recover the signer
    function getTypedDataHash(Event memory _event)
        public
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    _hashTypedDataV4(getStructHash(_event))
                )
            );
    }

    function getSigner(bytes32 structHash, uint8 v, bytes32 r, bytes32 s) public view returns (address signer) {
        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", _hashTypedDataV4(structHash)));
        signer = ECDSA.recover(hash, v, r, s);
    }
}
