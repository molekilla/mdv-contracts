pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../RLPReader/RLPReader.sol";
import "../WModels.sol";

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

}