pragma solidity ^0.8.0;

import "solidity-bytes-utils/BytesLib.sol";
import "openzeppelin-contracts/contracts/utils/Address.sol";
import "forge-std/console.sol";

enum ComparisonType {
    Lower,
    LowerOrEqual,
    Greater,
    GreaterOrEqual
}

library BytesExtractor {
    function extractComparisonType(bytes memory data, uint256 start)
        internal
        pure
        returns (ComparisonType cmp, uint256 newPosition)
    {
        uint8 _type = uint8(BytesLib.slice(data, start, 1)[0]);
        newPosition = start + 1;

        if (_type == uint8(0)) {
            cmp = ComparisonType.Lower;
        } else if (_type == uint8(1)) {
            cmp = ComparisonType.LowerOrEqual;
        } else if (_type == uint8(2)) {
            cmp = ComparisonType.Greater;
        } else if (_type == uint8(3)) {
            cmp = ComparisonType.GreaterOrEqual;
        } else {
            revert("Comparison type invalid");
        }
    }

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

    function handleBlockTimestamp(bytes calldata constraints, uint256 currentPosition)
        internal
        view
        returns (uint256 newPosition)
    {
        ComparisonType cmp;
        {
            (ComparisonType _cmp, uint256 _newPosition) =
                BytesExtractor.extractComparisonType(constraints, currentPosition);
            currentPosition = _newPosition;
            cmp = _cmp;
        }

        {
            (uint256 timestamp, uint256 _newPosition) = BytesExtractor.extractTimestamp(constraints, currentPosition);

            if (cmp == ComparisonType.Lower) {
                require(timestamp > block.timestamp, "Block timestamp needs to be lower");
            } else if (cmp == ComparisonType.LowerOrEqual) {
                require(timestamp >= block.timestamp, "Block timestamp needs to be lower or equal");
            } else if (cmp == ComparisonType.Greater) {
                require(timestamp < block.timestamp, "Block timestamp needs to be greater");
            } else if (cmp == ComparisonType.GreaterOrEqual) {
                require(timestamp <= block.timestamp, "Block timestamp needs to be greater or equal");
            }

            newPosition = _newPosition;
        }
    }

    function handleBalanceOfComparison(address sender, bytes calldata constraints, uint256 currentPosition)
        internal
        returns (uint256 newPosition)
    {
        (address extractedAddress, uint256 _newPosition) =
            BytesExtractor.extractContractAddress(constraints, currentPosition + 1);

        uint256 balance = TokenHelper.balanceOf(extractedAddress, sender);

        newPosition = _newPosition;
    }

    function parseAndExectueConstraint(address sender, bytes calldata constraints) private {
        require(constraints.length > 0, "No constrain to parse");

        uint256 currentPosition = 0;

        while (currentPosition != constraints.length) {
            uint8 _type = uint8(constraints[currentPosition]);
            currentPosition += 1;

            if (_type == uint8(0)) {
                currentPosition = handleBlockTimestamp(constraints, currentPosition);
            } else if (_type == uint8(1)) {
                currentPosition = handleBalanceOfComparison(sender, constraints, currentPosition);
            } else {
                revert("Invalid constraint type");
            }
        }
    }
}
