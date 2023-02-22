pragma solidity ^0.8.0;

import "solidity-bytes-utils/BytesLib.sol";
import "openzeppelin-contracts/contracts/utils/Address.sol";
import "forge-std/console.sol";

library BytesExtractor {
    function extractTimestamp(bytes memory data, uint256 start)
        internal
        pure
        returns (uint256 timestamp, uint256 newPosition)
    {
        bytes memory timestampAsBytes = BytesLib.slice(data, start, 8);
        timestamp = uint256(bytes32(timestampAsBytes)) >> 192;

        newPosition = start + 8;
    }

    function extractAddress(bytes memory data, uint256 start)
        internal
        pure
        returns (address extractedAddress, uint256 newPosition)
    {
        bytes memory addressAsBytes = BytesLib.slice(data, start, 20);

        assembly {
            extractedAddress := mload(add(addressAsBytes, 20))
        }
        newPosition = start + 20;
    }

    function extractContractAddress(bytes memory data, uint256 start)
        internal
        pure
        returns (address extractedAddress, uint256 newPosition)
    {
        (address _extractedAddress, uint256 _newPosition) = extractAddress(data, start);

        // require(Address.isContract(extractedAddress), "Extracted address is not a contract");

        extractedAddress = _extractedAddress;
        newPosition = _newPosition;
    }
}

library TokenHelper {
    string constant balanceOfFunctionSignature = "balanceOf(address)";

    function balanceOf(address token, address owner) public returns (uint256 balance) {
        (bool success, bytes memory returnData) = token.call(abi.encodeWithSignature(balanceOfFunctionSignature, owner));

        require(success, "BalanceOf call failed");
        balance = abi.decode(returnData, (uint256));
    }
}

contract Constraint {
    function applyConstraint(address sender, bytes calldata constraints)
        public
        returns (bytes memory characteristics)
    {
        if (constraints.length == 0) {
            return characteristics;
        }

        parseAndExectueConstraint(sender, constraints);
    }

    function parseAndExectueConstraint(address sender, bytes calldata constraints) private {
        require(constraints.length > 0, "No constrain to parse");

        uint256 currentPosition = 0;

        while (currentPosition != constraints.length) {
            uint8 _type = uint8(constraints[currentPosition]);

            if (_type == uint8(0)) {
                (uint256 timestamp, uint256 newPosition) =
                    BytesExtractor.extractTimestamp(constraints, currentPosition + 1);
                require(timestamp < block.timestamp, "Block timestamp constraint is greater than required");
                currentPosition = newPosition;
            } else if (_type == uint8(1)) {
                (uint256 timestamp, uint256 newPosition) =
                    BytesExtractor.extractTimestamp(constraints, currentPosition + 1);
                require(timestamp > block.timestamp, "Block timestamp constraint is lower than required");
                currentPosition = newPosition;
            } else if (_type == uint8(2)) {
                (address extractedAddress, uint256 newPosition) =
                    BytesExtractor.extractContractAddress(constraints, currentPosition + 1);

                uint256 balance = TokenHelper.balanceOf(extractedAddress, sender);

                console.log(balance);
                currentPosition = newPosition;
            } else {
                revert("Invalid constraint type");
            }
        }
    }
}
