pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred (
        address indexed previousOwner,
        address indexed newOwner
    );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
    constructor() public {
        owner = msg.sender;
    }

  /**
   * @dev Throws if called by any account other than the owner.
   */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

contract ERC721  is ERC165 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) public view returns (address);

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) public view returns (bool);
}


interface ERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
}


contract AACContract is Ownable, ERC721 {
    
    struct AAC {
        // owner ID list
        address owner;
        // timestamp
        uint timestamp;
        // seed
        bytes32 seed;
        // exp
        uint exp;
        // public data
        
        // encrypted data
        
    }
    
    // the first element in aacArray must be invalid for uidToAacIndex to work
    AAC[] aacArray;
    mapping (uint => uint) public uidToAacIndex;
    mapping (bytes32 => uint) public keyBToUid;
    
    mapping (address => bytes32) addressToKeyA;
    mapping (address => bytes32) addressToKeyB;
    uint public aacPrice = 0.0025 ether;
    uint nonce;
    
    // id must correspond to a valid AAC
    modifier mustExist(uint _tokenId) {
        require (uidToAacIndex[_tokenId] != 0);
        _;
    }
    
    // sender must own the AAC
    modifier mustOwn(uint _tokenId) {
        require (ownerOf(_tokenId) == msg.sender);
        _;
    }

    function changeAacPrice(uint _newPrice) external onlyOwner {
        aacPrice = _newPrice;
    }

    function mint(bytes7 _uid) external payable {
        require (msg.value >= aacPrice);
        require(_uid != 0);
        uint index = aacArray.push(AAC(msg.sender, block.timestamp, _generateRandomNumber(), 0));
        uidToAacIndex[uint(_uid)] = index;
        bytes32 keyB = _generateRandomNumber();
        addressToKeyB[msg.sender] = keyB;
        keyBToUid[keyB] = uint(_uid);

        emit Transfer(0, msg.sender, uint(_uid));
    }

    function getAac(uint _uid) external view mustExist(_uid) returns (address, uint, bytes32, uint) {
        AAC memory aac = aacArray[uidToAacIndex[_uid]];
        return(aac.owner, aac.timestamp, aac.seed, aac.exp);
    }

    function _generateRandomNumber() private returns (bytes32) {
        nonce++;
        return keccak256(
            abi.encodePacked(block.timestamp, msg.sender, nonce)
        );
    }
    
    //--------------------------------------------------------------------------
    // ERC-165 support
    //--------------------------------------------------------------------------
    mapping (bytes4 => bool) interfaceIdToIsSupported;
    
    function setInterfaceSupport(bytes4 interfaceID, bool value) external onlyOwner {
        interfaceIdToIsSupported[interfaceID] = value;
    }
    
    function supportsInterface(bytes4 interfaceID) external view returns (bool) {
        return interfaceIdToIsSupported[interfaceID];
    }
    
    
    //--------------------------------------------------------------------------
    // ERC-721 support
    //--------------------------------------------------------------------------
    
    // Mapping from token ID to approved address
    mapping (uint => address) idToApprovedAddress;
    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) internal operatorApprovals;
    
    function ownerOf(uint256 _tokenId) public view mustExist(_tokenId) returns (address) {
        // owner must not be the zero address
        require (aacArray[uidToAacIndex[_tokenId]].owner != 0);
        return aacArray[uidToAacIndex[_tokenId]].owner;
    }
    
    function balanceOf(address _owner) external view returns (uint256) {
        // owner must not be the zero address
        require (_owner != 0);
        uint owned;
        for (uint i = 1; i < aacArray.length; ++i) {
            if(aacArray[i].owner == _owner) {
                ++owned;
            }
        }
        return owned;
    }
    
    function approve(address _approved, uint256 _tokenId) external payable {
        address owner = ownerOf(_tokenId);
        // msg.sender must be the current NFT owner, or an authorized operator of the current owner.
        require (msg.sender == owner || isApprovedForAll(owner, msg.sender));
        idToApprovedAddress[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);
    }
    
    function getApproved(uint256 _tokenId) external view mustExist(_tokenId) returns (address) {
        return idToApprovedAddress[_tokenId];
    }
    
    function setApprovalForAll(address _operator, bool _approved) external {
        require(_operator != msg.sender);
        operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    
    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external mustExist(_tokenId) payable {
        address owner = ownerOf(_tokenId);
        // sender must be the current owner, an authorized operator, or the approved address for the AAC
        require (msg.sender == owner || isApprovedForAll(owner, msg.sender) || msg.sender == idToApprovedAddress[_tokenId]);
        // _from address must be current owner of the AAC
        require (_from == owner && _from != 0);
        // _to address must not be zero address
        require (_to != 0);
        
        // clear approval
        idToApprovedAddress[_tokenId] = 0;
        // transfer ownership
        aacArray[uidToAacIndex[_tokenId]].owner = _to;

        emit Transfer(_from, _to, _tokenId);

        // check and call onERC721Received. Throws and rolls back the transfer if _to does not implement the expected interface
        uint size;
        assembly { size := extcodesize(_to) }
        if (size > 0) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, "");
            require(retval == 0x150b7a02);
        }
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) external mustExist(_tokenId) payable {
        address owner = ownerOf(_tokenId);
        // sender must be the current owner, an authorized operator, or the approved address for the AAC
        require (msg.sender == owner || isApprovedForAll(owner, msg.sender) || msg.sender == idToApprovedAddress[_tokenId]);
        // _from address must be current owner of the AAC
        require (_from == owner && _from != 0);
        // _to address must not be zero address
        require (_to != 0);
        
        // clear approval
        idToApprovedAddress[_tokenId] = 0;
        // transfer ownership
        aacArray[uidToAacIndex[_tokenId]].owner = _to;

        emit Transfer(_from, _to, _tokenId);

        // check and call onERC721Received. Throws and rolls back the transfer if _to does not implement the expected interface
        uint size;
        assembly { size := extcodesize(_to) }
        if (size > 0) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            require(retval == 0x150b7a02);
        }
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external mustExist(_tokenId) payable {
        address owner = ownerOf(_tokenId);
        // sender must be the current owner, an authorized operator, or the approved address for the AAC
        require (msg.sender == owner || isApprovedForAll(owner, msg.sender) || msg.sender == idToApprovedAddress[_tokenId]);
        // _from address must be current owner of the AAC
        require (_from == owner && _from != 0);
        // _to address must not be zero address
        require (_to != 0);
        
        // clear approval
        idToApprovedAddress[_tokenId] = 0;
        // transfer ownership
        aacArray[uidToAacIndex[_tokenId]].owner = _to;

        emit Transfer(_from, _to, _tokenId);
    }
}