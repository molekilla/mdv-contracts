pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;


import "../WStep.sol";
import "../WFStorage.sol";
import '../ExtensionEventRegistry.sol';
import "./LibRecetaDocument.sol";


contract RecetaModel is WFStorage, ExtensionEventRegistry, LibRecetaDocument {
    
    address owner;

    mapping (uint256 => DocumentPayload) public table;
    ExtensionEventRegistry private extReg;
    constructor(address r) public WFStorage() {
        owner = msg.sender;
        extReg = ExtensionEventRegistry(r);
    }

    
    function onAddRow(
        address to,
        address sender, 
        WStep memory current,
        WStep memory next, 
        bytes memory payload
        ) public nonReentrant returns (bool) {

        currentDocumentIndex = rowCount;
        rowCount = rowCount + 1;

        if (hasAttachedFiles(rowCount + 1)) return false;        
        table[rowCount-1] = this.getTableFromRlp(rowCount - 1, payload);
        table[rowCount-1].stepInfo.user = sender;
        table[rowCount-1].stepInfo.recipient = to;
        table[rowCount-1].stepInfo.status = keccak256(abi.encodePacked(next.current));

        return true;
    }

    function onUpdate(uint256 doc, 
        address to,
        address sender, 
        WStep memory current,
        WStep memory next, 
        bytes memory payload
        ) public returns (bool) {

        validateSender(current,  sender);
        validateRecipient(current, to);
        validateStatus(next, current.current);

        currentDocumentIndex = doc;

        table[doc].stepInfo.status = keccak256(abi.encodePacked(next.current));
        if (table[doc].documentStatus == 1) {
            // 1 = updated, 0 = nothing
            updateFilesMapping(doc, payload);
        }

        return true;
    }

    function updateSwitch(uint256 doc, address to, address sender,
        WStep memory currentStep,
        WStep memory nextStep,
        uint256 extensionEvtId,
        bytes memory fields
        ) public returns (bool, uint256) {
         
        uint256 calculatedNextFork = currentStep.next;
        if (currentStep.forkId > 0) {
            calculatedNextFork = currentStep.forkId;
        }
        this.onUpdate(doc, to, sender, currentStep, nextStep, fields);    
        return (true, calculatedNextFork);
    }


    
}
