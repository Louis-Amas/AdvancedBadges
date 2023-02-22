pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/SignatureChecker.sol";
import "./MintingConstraint.sol";
import "./SignatureUtils.sol";

contract AdvancedBadge is ERC721Enumerable, SignatureUtils {
    MintingConstraint private mintingConstraintContract;

    struct Event {
        address creator;
        bytes mintingConstraints;
    }

    bytes32 public constant BADGE_TYPE_HASH = keccak256("Event(address creator,bytes mintingConstraints)");

    event NewEvent(address indexed creator, bytes32 eventHash);

    uint256 public lastERC721Id;

    mapping(bytes32 => Event) public eventsByHash;

    // TokenId to  characteristics
    mapping(uint256 => bytes) public characteristicsByTokenId;

    constructor(address mintingConstraintAddress, string memory name, string memory symbol) ERC721(name, symbol) {
        mintingConstraintContract = MintingConstraint(mintingConstraintAddress);
    }

    function getStructHash(Event memory _event) internal pure returns (bytes32) {
        return keccak256(abi.encode(BADGE_TYPE_HASH, _event.creator, _event.mintingConstraints));
    }

    function createEvent(Event calldata _event) public returns (bytes32 eventHash) {
        eventHash = getStructHash(_event);

        Event storage eventStruct = eventsByHash[eventHash];

        require(eventStruct.creator == address(0), "Event already exists");
        require(_event.creator == msg.sender, "Creator needs to be msg.sender");

        eventStruct.creator = _event.creator;
        eventStruct.mintingConstraints = _event.mintingConstraints;

        eventsByHash[eventHash] = eventStruct;

        emit NewEvent(_event.creator, eventHash);
    }

    function mintBadgeWithSignature(address signer, bytes32 eventHash, bytes calldata signature)
        public
        SignatureUtils.verifySignature(signer, eventHash, signature)
    {
        mintBadge(signer, eventHash);
    }

    function mintBadge(address to, bytes32 eventHash) public {
        require(to == msg.sender, "Only sender can mint badge");
        Event storage eventStruct = eventsByHash[eventHash];

        require(eventStruct.creator != address(0), "Event does not exists");

        bytes memory characteristics = mintingConstraintContract.canMint(to, eventStruct.mintingConstraints);

        _mint(to, lastERC721Id);
        characteristicsByTokenId[lastERC721Id] = characteristics;
        lastERC721Id++;
    }
}
