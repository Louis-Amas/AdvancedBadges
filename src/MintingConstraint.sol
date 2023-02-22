pragma solidity ^0.8.0;

import "solidity-bytes-utils/BytesLib.sol";
import "forge-std/console.sol";

library BytesExtractor {

    function extractTimestamp(bytes memory data, uint256 start) internal pure returns(uint256 timestamp, uint256 newPosition) {
        bytes memory timestampAsBytes = BytesLib.slice(data, start, 8);
        timestamp = uint256(bytes32(timestampAsBytes)) >> 192;
        newPosition = start + 8;
    }
}

contract MintingConstraint {

    function canMint(address sender, bytes calldata constraints) public view returns(bytes memory characteristics) {
        if (constraints.length == 0) {
            return characteristics;
        }

        parseAndExectueConstraint(sender, constraints);
    }

    function parseAndExectueConstraint(
        address /*sender*/,
        bytes calldata constraints
    ) private view {
        require(constraints.length > 0, "No constrain to parse");

        uint256 currentPosition = 0;

        while (currentPosition != constraints.length) {
            bytes1 _type = constraints[currentPosition];

            if (_type == bytes1(0)) {
                (uint256 timestamp, uint256 newPosition)= BytesExtractor.extractTimestamp(constraints, currentPosition + 1);
                require(timestamp < block.timestamp, "Block timestamp constraint is greater than required");
                currentPosition = newPosition;
            } else if (_type == bytes1(uint8(1))) {
                (uint256 timestamp, uint256 newPosition) = BytesExtractor.extractTimestamp(constraints, currentPosition + 1);
                require(timestamp > block.timestamp, "Block timestamp constraint is lower than required");
                currentPosition = newPosition;
            } else {
                revert("Invalid constraint type");
            }
        }

    }
}
