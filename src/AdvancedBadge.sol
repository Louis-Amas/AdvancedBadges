pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract AdvancedBadge is ERC721Enumerable {

    struct Event {
        address creator;
        bytes mintingConstraints;
    }

    bytes32 constant public BADGE_TYPE_HASH = keccak256(
        "Event(address creator,bytes mintingConstraints)"
    );

    event NewEvent(
        address indexed creator,
        bytes32 eventHash
    );

    uint256 public lastERC721Id;

    mapping(bytes32 => Event) public eventsByHash;

    constructor(string memory name, string memory symbol) ERC721(name, symbol){
    }

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

    function createEvent(
        Event calldata _event
    ) public returns(bytes32 eventHash) {
        eventHash = getStructHash(_event);

        Event storage eventStruct = eventsByHash[eventHash];

        require(eventStruct.creator == address(0), "Event already exists");
        require(
            _event.creator == msg.sender,
            "Creator needs to be msg.sender"
        );

        eventStruct.creator = _event.creator;
        eventStruct.mintingConstraints = _event.mintingConstraints;

        eventsByHash[eventHash] = eventStruct;

        emit NewEvent(_event.creator, eventHash);
    }
}
