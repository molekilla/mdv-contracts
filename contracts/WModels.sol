pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../RLPReader/RLPReader.sol";

contract WModels {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for RLPReader.Iterator;
    using RLPReader for bytes;
    
    mapping (uint256 => mapping (bytes32 => FileDocument)) internal files;
    mapping (uint256 => uint256) internal filesCount;

    // Generic PersonaInfo model
    struct PersonaInfo {
        string fullName;
        string did;
        string url;
        address ethereumAddress;
    }

    // Generic StepInfo Model
    struct StepInfo {
        address user;
        address recipient;
        bytes32 status;
    }

    // Generic DocumentInfoModel
    struct DocumentInfo {
        FileDocument[] files;
        uint256 status;
    }

    struct FileDocument {
        string contentType;
        string path;
        string hash;
    }

    function hasAttachedFiles(uint256 docId) public returns (bool) {
        return filesCount[docId] > 0;
    }
    
    function addToFilesMapping(uint256 docId, bytes memory rlpBytes) internal {
        RLPReader.RLPItem[] memory items = rlpBytes.toRlpItem().toList();
        RLPReader.Iterator memory _files = items[1].iterator();
        
        uint256 index = 0;
        while (_files.hasNext()) {
            RLPReader.RLPItem[] memory file = _files.next().toList();
            bytes32 key = keccak256(abi.encodePacked(file[1].toBytes()));
            files[docId][key] = FileDocument(
                string(file[0].toBytes()),
                string(file[1].toBytes()),
                string(file[2].toBytes())
            );
            index++;
        }
        filesCount[docId] = index;
    }

    function updateFilesMapping(uint256 docId, bytes memory rlpBytes) internal {
        RLPReader.RLPItem[] memory payload = rlpBytes.toRlpItem().toList();
        RLPReader.Iterator memory _files = payload[1].toList()[1].iterator();
        
       // uint256 index = 0;
        while (_files.hasNext()) {
            RLPReader.RLPItem[] memory file = _files.next().toList();
            bytes32 key = keccak256(abi.encodePacked(file[1].toBytes()));
           
            files[docId][key] = FileDocument(
                string(file[0].toBytes()),
                string(file[1].toBytes()),
                string(file[2].toBytes())
            );
           // index++;
        }
        // filesCount[docId] = index;
    }


    // toStepInfo converts RLP to StepInfo struct
    function toStepInfo(bytes memory payload) public returns (StepInfo memory) {
        // address user;
        // address recipient;
        // bytes32 status;
        RLPReader.RLPItem[] memory document = payload.toRlpItem().toList();
        return StepInfo(
            document[0].toAddress(),
            document[1].toAddress(),
            bytes32(document[2].toUint())
        );
    }

    function toEmtpyStepInfo() public returns (StepInfo memory) {
        return StepInfo(address(0),address(0), bytes32(0));
    }
}