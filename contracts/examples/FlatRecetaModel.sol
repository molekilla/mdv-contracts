pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;


import "../WModels.sol";
import "../WStep.sol";
import "../WFStorage.sol";
import '../ExtensionEventRegistry.sol';
import "../RLPReader/RLPReader.sol";


contract LibRecetaDocument is WModels {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for RLPReader.Iterator;
    using RLPReader for bytes;


    // DocumentPayload is the struct used by the client
    struct DocumentPayload {
        RecetaDocument receta;
        StepInfo       stepInfo;
        uint256 documentStatus;
    }

    // RecetaDocument is the model used by the workflow
    struct RecetaDocument {
        string description;
        PersonaInfo doctor;
        PersonaInfo patient;
        PersonaInfo pharmacy;
        uint256 totalAmount;
        uint256 tax;
    }

    function getTableFromRlp(uint256 docId, bytes memory rlpBytes) public returns (DocumentPayload memory) {
        /*
        * getTableFromRlp reads a RLP encoded argument and converts it to a model
        * DocumentPayload = [[RecetaDocument], [DocumentInfo], [StepInfo]]
        * RecetaDocument = [description, PersonaInfo, PersonaInfo, PersonaInfo, totalAmount, tax]
        * StepInfo = [user, recipient, status]
        * PersonaInfo = [fullName, did, url, ethereumAddress]
        */
        RLPReader.RLPItem[] memory payload = rlpBytes.toRlpItem().toList();
        RecetaDocument memory doc = toReceta(payload[0].toRlpBytes());
        addToFilesMapping(docId, payload[1].toRlpBytes());
        DocumentPayload memory res = DocumentPayload({
            documentStatus: payload[1].toList()[0].toUint(),
            receta: doc,
            stepInfo: toEmtpyStepInfo()
        });
        return  res;
    }



    function toReceta(bytes memory rlpBytes) internal returns (RecetaDocument memory) {
        // string description;
        // PersonaInfo patient;
        // PersonaInfo doctor;
        // PersonaInfo pharmacy;
        // PersonaInfo delivery;
        // uint256 totalAmount;
        // uint256 tax;
        RLPReader.RLPItem[] memory payload = rlpBytes.toRlpItem().toList();
        
        return RecetaDocument(
            string(payload[0].toBytes()),
            PersonaInfo(
                string(payload[1].toList()[0].toBytes()),
                string(payload[1].toList()[1].toBytes()),
                string(payload[1].toList()[2].toBytes()),
                (payload[1].toList()[3].toAddress())
            ),
            PersonaInfo(
                string(payload[2].toList()[0].toBytes()),
                string(payload[2].toList()[1].toBytes()),
                string(payload[2].toList()[2].toBytes()),
                (payload[2].toList()[3].toAddress())
            ),
            PersonaInfo(
                string(payload[3].toList()[0].toBytes()),
                string(payload[3].toList()[1].toBytes()),
                string(payload[3].toList()[2].toBytes()),
                (payload[3].toList()[3].toAddress())
            ),
            payload[4].toUint(),
            payload[5].toUint()
        );

    }

};


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
