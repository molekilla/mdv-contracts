pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./WStep.sol";


abstract contract IWModel  is LibWStep { 

    function getCurrentModelIndex() public virtual view returns (uint256);
    
    function onAddRow( 
        address to,
        address sender, 
        WStep memory current,
        WStep memory next,
        bytes memory fields
        ) public virtual returns (bool);
    function createValidations(uint256 index, WStep memory step) public virtual returns (bool);
    function updateSwitch(
        uint256 doc,
        address to, 
        address sender,
        WStep memory current,
        WStep memory next,
        uint256 extensionEvtId,
        bytes memory fields
        ) public virtual returns (bool, uint256);
}
