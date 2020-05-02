pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;


import './IExtension.sol';

contract ExtensionEventRegistry {
    event LogAddExtEvent(uint256 indexed id);

    address private owner;
    struct ExtEventEntry {
        uint256 id;
        address extContract;
        string name;

    }
    uint256 private count;
    mapping (uint256 => ExtEventEntry) private eventRegistry;

    constructor() public {
        owner = msg.sender;
    }

    function add(string memory name, address caller, uint256 id) public returns (uint256) {
        require(owner == msg.sender);
        count++;
        eventRegistry[count] = ExtEventEntry({
            id: id,
            name: name,
            extContract: caller
        });
        emit LogAddExtEvent(count);
        return count;
    }

    function has(uint256 id) public view returns(bool) {
        return eventRegistry[id].extContract != address(0);
    }

    function edit(uint256 extid, uint256 id) public returns (bool) {
        require(owner == msg.sender);

        eventRegistry[extid].id = id;
        return true;
    }

    function read(uint256 id) public view returns (ExtEventEntry memory) {
        // require(eventRegistry[id].extContract != address(0), "WF_INVALID_CONTRACT");

        return eventRegistry[id];
    }
}