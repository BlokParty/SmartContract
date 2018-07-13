pragma solidity ^0.4.24;

contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred (
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}


contract ERC721 is ERC165 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) public view returns (uint256);
    function ownerOf(uint256 _tokenId) public view returns (address);

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) public view returns (bool);
}


interface ERC721Enumerable {
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 _index) external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}


interface ERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
}


contract AACToken is Ownable, ERC721, ERC721Enumerable {

    struct AAC {
        // owner ID list
        address owner;
        // unique identifier
        uint uid;
        // timestamp
        uint timestamp;
        // exp
        uint exp;
        // public data
        bytes publicData;
        // encrypted data
        //bytes privateData;        // use this if/when needed
    }
    
    // the first element in aacArray must be invalid for uidToAacIndex to work
    AAC[] aacArray;
    mapping (uint => uint) uidToAacIndex;
    
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
    
    function balanceOf(address _owner) public view returns (uint256) {
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
    
    function tokensOfOwner(address _owner) external view returns (uint[]) {
        uint aacsOwned = balanceOf(_owner);
        require(aacsOwned > 0);
        uint counter = 0;
        uint[] memory result = new uint[](aacsOwned);
        for (uint i = 0; i < aacArray.length; i++) {
            if(aacArray[i].owner == _owner) {
                result[counter] = aacArray[i].uid;
                counter++;
            }
        }
        return result;
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
    
    //--------------------------------------------------------------------------
    // ERC-721 Enumerable support
    //--------------------------------------------------------------------------
    
    function totalSupply() external view returns (uint256) {
        return (aacArray.length - 1);
    }
    
    function tokenByIndex(uint256 _index) external view onlyOwner returns (uint256) {
        // index must correspond to an existing AAC
        require (_index > 0 && _index < aacArray.length);
        return (aacArray[_index].uid);
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
        uint aacsOwned = balanceOf(_owner);
        require(_owner != 0);
        require(aacsOwned > 0);
        require(_index < aacsOwned);
        uint counter = 0;
        for (uint i = 0; i < aacArray.length; i++) {
            if (aacArray[i].owner == _owner) {
                if (counter == _index) {
                    return(aacArray[i].uid);
                } else {
                    counter++;
                }
            }
        }
    }
}


    
contract AACFunctionality is AACToken {
    event Link(uint _oldUid, uint _newUid);
    
    uint public aacPrice = 0.0025 ether;
    uint nonce;
    uint constant uidBuffer = 100000000000000000; // 17 zeroes
    address playToken = 0x3bD0719846900fA6D73f992f7d2538820e8b193A;

    bytes4 spendAndMintFunctionHash;

    function changeAacPrice(uint _newPrice) external onlyOwner {
        aacPrice = _newPrice;
    }

    function mintAndSend(address _to) external {
        require(msg.sig == spendAndMintFunctionHash);

        uint uid = uidBuffer + aacArray.length;
        uint index = aacArray.push(AAC(_to, uid, block.timestamp, 0, ""));
        uidToAacIndex[uid] = index - 1;

        emit Transfer(0, msg.sender, uid);
    }

    function link(bytes7 _newUid, uint _aacId, bytes _publicData) external mustExist(_aacId) {
        AAC storage aac = aacArray[uidToAacIndex[_aacId]];
        // sender must own AAC
        require (msg.sender == aac.owner);
        // _aacId must be an empty AAC
        require (_aacId > uidBuffer);
        // _newUid field cannot be empty
        require (_newUid > 0);
        // an AAC with the new UID must not currently exist
        require (uidToAacIndex[uint(_newUid)] == 0);

        // set new UID's mapping to index to old UID's mapping
        uidToAacIndex[uint(_newUid)] = uidToAacIndex[_aacId];
        // reset old UID's mapping to index
        uidToAacIndex[_aacId] = 0;
        // set AAC's UID to new UID
        aac.uid = uint(_newUid);
        // set any public data
        aac.publicData = _publicData;

        emit Link(_aacId, uint(_newUid));
    }

    function getAac(uint _uid) external view mustExist(_uid) returns (address, uint, uint, uint, bytes) {
        AAC memory aac = aacArray[uidToAacIndex[_uid]];
        return(aac.owner, aac.uid, aac.timestamp, aac.exp, aac.publicData);
    }

    function _generateRandomNumber() private returns (bytes32) {
        nonce++;
        return keccak256(
            abi.encodePacked(block.timestamp, msg.sender, nonce)
        );
    }
}