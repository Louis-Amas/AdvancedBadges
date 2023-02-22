pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/SignatureChecker.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import "./Constraint.sol";
import "./SignatureUtils.sol";

contract AdvancedBadge is EIP712, ERC721Enumerable, SignatureUtils {
    Constraint private ConstraintContract;

    struct Event {
        address creator;
        bytes Constraints;
    }

    bytes32 public constant BADGE_TYPE_HASH = keccak256("Event(address creator,bytes Constraints)");

    event NewEvent(address indexed creator, bytes32 eventHash);

    uint256 public lastERC721Id;

    mapping(bytes32 => Event) public eventsByHash;

    // TokenId to  characteristics
    mapping(uint256 => bytes) public characteristicsByTokenId;

    constructor(address ConstraintAddress, string memory name, string memory symbol)
        EIP712("AdvancedBadge", "1")
        ERC721(name, symbol)
    {
        ConstraintContract = Constraint(ConstraintAddress);
    }

    function getStructHash(Event memory _event) internal pure returns (bytes32) {
        return keccak256(abi.encode(BADGE_TYPE_HASH, _event.creator, _event.Constraints));
    }

    function getTypedDataHash(Event memory _event) public view returns (bytes32 eventHash, bytes32 typedDataHash) {
        eventHash = getStructHash(_event);
        typedDataHash = keccak256(abi.encodePacked("\x19\x01", _hashTypedDataV4(eventHash)));
    }

    function createEvent(Event calldata _event) public returns (bytes32 eventHash) {
        eventHash = getStructHash(_event);

        Event storage eventStruct = eventsByHash[eventHash];

        require(eventStruct.creator == address(0), "Event already exists");
        require(_event.creator == msg.sender, "Creator needs to be msg.sender");

        eventStruct.creator = _event.creator;
        eventStruct.Constraints = _event.Constraints;

        eventsByHash[eventHash] = eventStruct;

        emit NewEvent(_event.creator, eventHash);
    }

    function mintBadge(address to, bytes32 eventHash) public {
        require(to == msg.sender, "Only sender can mint badge");
        _mintBadge(msg.sender, eventHash);
    }

    struct Parameters {
        address signer;
        Event eventStruct;
        bytes signature;
    }

    function batchMintBadges(Parameters[] calldata parameters) public {
        for (uint256 i = 0; i < parameters.length; ++i) {
            mintBadgeWithSignature(parameters[i].signer, parameters[i].eventStruct, parameters[i].signature);
        }
    }

    function mintBadgeWithSignature(address signer, Event calldata eventStruct, bytes calldata signature) public {
        (bytes32 eventHash, bytes32 typedEventHash) = getTypedDataHash(eventStruct);

        _mintBadgeWithSignature(signer, eventHash, typedEventHash, signature);
    }

    function _mintBadgeWithSignature(
        address signer,
        bytes32 eventHash,
        bytes32 typedEventHash,
        bytes calldata signature
    ) internal SignatureUtils.verifySignature(signer, typedEventHash, signature) {
        _mintBadge(signer, eventHash);
    }

    function _mintBadge(address to, bytes32 eventHash) internal {
        Event storage eventStruct = eventsByHash[eventHash];

        require(eventStruct.creator != address(0), "Event does not exists");

        bytes memory characteristics = ConstraintContract.canMint(to, eventStruct.Constraints);

        _mint(to, lastERC721Id);
        characteristicsByTokenId[lastERC721Id] = characteristics;
        lastERC721Id++;
    }
}
