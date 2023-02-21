pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/SignatureChecker.sol";
import "./AdvancedBadgeSigUtils.sol";
import "forge-std/console.sol";

contract AdvancedBadge is AdvancedBadgeSigUtils, ERC721Enumerable, Ownable {

    event NewEvent(
        address indexed creator,
        bytes32 eventHash
    );

    uint256 public lastERC721Id;

    mapping(bytes32 => Event) public eventsByHash;

    constructor(string memory name, string memory symbol) ERC721(name, symbol){
    }

    function createEvent(
        Event calldata _event,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public returns(bytes32 eventHash) {
        eventHash = getStructHash(_event);

        Event storage eventStruct = eventsByHash[eventHash];

        require(eventStruct.creator == address(0), "Event already exists");
        require(
            getSigner(eventHash, v, r, s) == _event.creator,
            "Invalid signature"
        );

        eventStruct.creator = _event.creator;
        eventStruct.mintingConstraints = _event.mintingConstraints;

        eventsByHash[eventHash] = eventStruct;

        emit NewEvent(_event.creator, eventHash);
    }
}
