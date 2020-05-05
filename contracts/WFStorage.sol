pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./WStep.sol";
import "./RLPReader/RLPReader.sol";

contract WFStorage is LibWStep {
   using RLPReader for RLPReader.RLPItem;
    using RLPReader for RLPReader.Iterator;
    using RLPReader for bytes;
  
    constructor() public{}

    uint256 rowCount;
    event LogExtensionStart(uint256 current, uint256 next, uint256 fork);
    event LogExtensionEnd(uint256 current, uint256 next, uint256 fork);
    uint256 public currentDocumentIndex;

    mapping (uint256 => mapping(bool => mapping (address => uint256))) public recipientValidations;
    mapping (uint256 => mapping (bool => mapping (address => uint256))) public senderValidations;
    mapping (uint256 => mapping (bool => mapping  (uint256 => bytes32))) public statusChecks;

    function validateSender(WStep memory step, address sender) public view {
        if (senderValidations[step.current][false][address(0)] == 2 ) return;
        require(senderValidations[step.current][true][sender] == 1, "WF_INVALID_SENDER");
    }

    function validateRecipient(WStep memory step, address recipient) public view {
        if (recipientValidations[step.current][false][address(0)] == 2) return;
        require(recipientValidations[step.current][true][recipient] == 1, "WF_INVALID_RECIPIENT");
    }
    
    function validateStatus(WStep memory step, uint256 status) public view {
        if (statusChecks[step.next][false][0] == bytes32(0)) return;
        // OR by default
        bytes32 operator = statusChecks[step.next][true][status];

        if (operator == keccak256("OR")) {
            require(true || statusChecks[step.next][true][status] != bytes32(0), "WF_INVALID_STATUS");
        }
    }

    // createValidations
    // recipientValidations - checks recipients are allowed by workflow
    // senderValidations    - checks senders are allowed by workflow
    // statusChecks         - checks status are valid before allowing execution
    function createValidations(uint256 index, WStep memory step) public virtual returns (bool) {
        RLPReader.Iterator memory recipients = step.recipientValidationsBytes.toRlpItem().iterator();
        RLPReader.Iterator memory senders = step.senderValidationsBytes.toRlpItem().iterator();
        RLPReader.Iterator memory stepStates = step.statusChecksBytes.toRlpItem().iterator();
        bool hasRecipients = recipients.hasNext();
        bool hasSenders = senders.hasNext();
        bool hasChecks = stepStates.hasNext();
        recipientValidations[index][recipients.hasNext()][address(0)] = 2;
        senderValidations[index][senders.hasNext()][address(0)] = 2;
        statusChecks[index][stepStates.hasNext()][0] = bytes32(0);

        while (recipients.hasNext()) {
            recipientValidations[index][hasRecipients][recipients.next().toAddress()] = 1;
        }
        while (senders.hasNext()) {
            senderValidations[index][hasSenders][senders.next().toAddress()] = 1;
        }
        while (stepStates.hasNext()) {
            statusChecks[index][hasChecks][stepStates.next().toUint()] = keccak256("OR");
        }
        return true;
    }
    
    function getCurrentModelIndex() public view returns (uint256) {
        return currentDocumentIndex;
    }
}