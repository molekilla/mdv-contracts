pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../node_modules/@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./WStep.sol";

contract WFStorage is LibWStep {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    event LogExtensionStart(uint256 current, uint256 next, uint256 fork);
    event LogExtensionEnd(uint256 current, uint256 next, uint256 fork);
    uint256 public currentDocumentIndex;
    uint256 public rowCount;

    // steps by initial state
    mapping(uint256 => WStep) public stepsByInitState;
    uint256  private stepCount;
    mapping (uint256 => EnumerableSet.AddressSet) internal rcptValidations;
    mapping (uint256 => EnumerableSet.AddressSet) internal senderValidations;
    mapping (uint256 => mapping (uint256 => bytes32)) internal statusChecks;


    function validateSender(uint256 next, address sender) public view {
        if (rcptValidations[next].length() > 0) {
        require(rcptValidations[next].contains(sender), "WF_INVALID_SENDER");
        }
    }

    function validateRecipient(uint256 next, address recipient) public view {
        if (senderValidations[next].length() > 0) {
        require(senderValidations[next].contains(recipient), "WF_INVALID_RECIPIENT");
        }
    }

    function validateStatus(uint256 next, uint256 status) public view {
        // OR by default
        bytes32 operator = statusChecks[next][status];

        if (operator == keccak256("OR")) {
            require(true || statusChecks[next][status] != bytes32(0), "WF_INVALID_STATUS");
        }
    }

    function getStep(uint256 index) public view returns (WStep memory) {
        return stepsByInitState[index];
    }

    function setStep(WStep memory step, uint256 index) public returns(bool) {
        require(stepCount < 40, "WF_STEP_LIMIT");
        stepsByInitState[index].current = step.current;
        stepsByInitState[index].currentActor = step.currentActor;
        stepsByInitState[index].next = step.next;
        stepsByInitState[index].mappingType = step.mappingType;
        
        for (uint i = 0; i < step.recipientValidations.length; ++i) {
            rcptValidations[index].add(step.recipientValidations[i]);
        }

        for (uint j = 0; j < step.senderValidations.length; ++j) {
            senderValidations[index].add(step.senderValidations[j]);
        }

        for (uint k = 0; k < step.stepValidations.length; ++k) {
            statusChecks[index][step.stepValidations[k]] = keccak256("OR");
        }
        stepsByInitState[index].forkId = step.forkId;
     
        stepCount++;
        return true;
    }

    function getCurrentModelIndex() public view returns (uint256) {
        return currentDocumentIndex;
    }
}