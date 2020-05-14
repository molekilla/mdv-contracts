pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;


abstract contract IExtension { 
    function canExec(uint256 id, address a) public virtual returns (bool);
    
    function executeExtension( 
        uint256 documentId,
        address sender, 
        bytes calldata data
        ) external virtual returns (bool);
}
