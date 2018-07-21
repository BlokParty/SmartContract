pragma solidity ^0.4.24;

//-----------------------------------------------------------------------------
/// @title AAC Ownership
//-----------------------------------------------------------------------------
contract AacOwnership {
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
    
    //-------------------------------------------------------------------------
    /// @dev Throws if AAC #`_tokenId` isn't tracked by the AAC Array.
    //-------------------------------------------------------------------------
    modifier mustExist(uint _tokenId) {
        require (uidToAacIndex[_tokenId] != 0);
        _;
    }

    //-------------------------------------------------------------------------
    /// @dev Throws if AAC #`_tokenId` isn't owned by sender.
    //-------------------------------------------------------------------------
    modifier mustOwn(uint _tokenId) {
        require (ownerOf(_tokenId) == msg.sender);
        _;
    }

    //-------------------------------------------------------------------------
    /// @dev Creates an empty AAC as a [0] placeholder for invalid AAC queries.
    //-------------------------------------------------------------------------
    constructor () public {
        aacArray.push(AAC(0,0,0,0,""));
    }

    //-------------------------------------------------------------------------
    /// @notice Find the owner of AAC #`_tokenId`
    /// @dev throws if `_owner` is the zero address.
    /// @param _tokenId The identifier for an AAC
    /// @return The address of the owner of the AAC
    //-------------------------------------------------------------------------
    function ownerOf(uint256 _tokenId) 
        public 
        view 
        mustExist(_tokenId) 
        returns (address) 
    {
        // owner must not be the zero address
        require (aacArray[uidToAacIndex[_tokenId]].owner != 0);
        return aacArray[uidToAacIndex[_tokenId]].owner;
    }

    //-------------------------------------------------------------------------
    /// @notice Count all AACs assigned to an owner
    /// @dev throws if `_owner` is the zero address.
    /// @param _owner An address to query
    /// @return The number of AACs owned by `_owner`, possibly zero
    //-------------------------------------------------------------------------
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

    //-------------------------------------------------------------------------
    /// @notice Get a list of AACs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid AACs.
    /// @param _owner Address to query for AACs.
    /// @return The complete list of Unique Indentifiers for AACs assigned to
    ///  `_owner`
    //-------------------------------------------------------------------------
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

    //-------------------------------------------------------------------------
    /// @notice Get number of AACs tracked by this contract
    /// @return A count of valid AACs tracked by this contract, where each one
    ///  has an assigned and queryable owner not equal to the zero address
    //-------------------------------------------------------------------------
    function totalSupply() external view returns (uint256) {
        return (aacArray.length - 1);
    }

    //-------------------------------------------------------------------------
    /// @notice Get the UID of AAC with index number `index`.
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The UID for the #`_index` AAC in the AAC array.
    //-------------------------------------------------------------------------
    function tokenByIndex(uint256 _index) external view returns (uint256) {
        // index must correspond to an existing AAC
        require (_index > 0 && _index < aacArray.length);
        return (aacArray[_index].uid);
    }

    //-------------------------------------------------------------------------
    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner Address to query for AACs.
    /// @param _index A counter less than `balanceOf(_owner)`
    /// @return The Unique Indentifier for the #`_index` AAC assigned to
    ///  `_owner`, (sort order not specified)
    //-------------------------------------------------------------------------
    function tokenOfOwnerByIndex(
        address _owner, 
        uint256 _index
    ) external view returns (uint256) {
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


//-----------------------------------------------------------------------------
/// @title Token Receiver Interface
//-----------------------------------------------------------------------------
interface TokenReceiverInterface {
    //-------------------------------------------------------------------------
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256(
    ///  "onERC721Received(address,address,uint256,bytes)"))` unless throwing
    //-------------------------------------------------------------------------
    function onERC721Received(
        address _operator, 
        address _from, 
        uint256 _tokenId, 
        bytes _data
    ) external returns(bytes4);
}


//-----------------------------------------------------------------------------
/// @title AAC Transfers
//-----------------------------------------------------------------------------
contract AacTransfers is AacOwnership {
    //-------------------------------------------------------------------------
    /// @dev Transfer emits when ownership of an AAC changes by any mechanism.
    ///  This event emits when AACs are created (`from` == 0) and destroyed
    ///  (`to` == 0). At the time of any transfer, the approved address
    ///  for that AAC (if any) is reset to address(0).
    //-------------------------------------------------------------------------
    event Transfer(
        address indexed _from, 
        address indexed _to, 
        uint256 indexed _tokenId
    );

    //-------------------------------------------------------------------------
    /// @dev Approval emits when the approved address for an AAC is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that AAC (if any) is reset to none.
    //-------------------------------------------------------------------------
    event Approval(
        address indexed _owner, 
        address indexed _approved, 
        uint256 indexed _tokenId
    );

    //-------------------------------------------------------------------------
    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all AACs of the owner.
    //-------------------------------------------------------------------------
    event ApprovalForAll(
        address indexed _owner, 
        address indexed _operator, 
        bool _approved
    );

    // Mapping from token ID to approved address
    mapping (uint => address) idToApprovedAddress;
    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) operatorApprovals;

    //-------------------------------------------------------------------------
    /// @notice Change or reaffirm the approved address for AAC #`_tokenId`.
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved AAC controller
    /// @param _tokenId The AAC to approve
    //-------------------------------------------------------------------------
    function approve(address _approved, uint256 _tokenId) external payable {
        address owner = ownerOf(_tokenId);
        // msg.sender must be the current NFT owner, or an authorized operator of the current owner.
        require (msg.sender == owner || isApprovedForAll(owner, msg.sender));
        idToApprovedAddress[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);
    }
    
    //-------------------------------------------------------------------------
    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if
    ///  there is none
    //-------------------------------------------------------------------------
    function getApproved(
        uint256 _tokenId
    ) external view mustExist(_tokenId) returns (address) {
        return idToApprovedAddress[_tokenId];
    }
    
    //-------------------------------------------------------------------------
    /// @notice Enable or disable approval for a third party ("operator") to
    ///  manage all of sender's AACs
    /// @dev Emits the ApprovalForAll event. The contract MUST allow multiple
    ///  operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke
    ///  approval
    //-------------------------------------------------------------------------
    function setApprovalForAll(address _operator, bool _approved) external {
        require(_operator != msg.sender);
        operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    
    function isApprovedForAll(
        address _owner, 
        address _operator
    ) public view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }

    
    //-------------------------------------------------------------------------
    /// @notice Transfers ownership of AAC #`_tokenId` from `_from` to `_to`
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, checks if
    ///  `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `0x150b7a02`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    //-------------------------------------------------------------------------
    function safeTransferFrom(
        address _from,
        address _to, 
        uint256 _tokenId
    ) external mustExist(_tokenId) payable {
        address owner = ownerOf(_tokenId);
        // sender must be the current owner, an authorized operator, or the
        //  approved address for the AAC
        require (
            msg.sender == owner || 
            isApprovedForAll(owner, msg.sender) || 
            msg.sender == idToApprovedAddress[_tokenId]
        );
        // _from address must be current owner of the AAC
        require (_from == owner && _from != 0);
        // _to address must not be zero address
        require (_to != 0);
        
        // clear approval
        idToApprovedAddress[_tokenId] = 0;
        // transfer ownership
        aacArray[uidToAacIndex[_tokenId]].owner = _to;

        emit Transfer(_from, _to, _tokenId);

        // check and call onERC721Received. Throws and rolls back the transfer
        //  if _to does not implement the expected interface
        uint size;
        assembly { size := extcodesize(_to) }
        if (size > 0) {
            bytes4 retval = TokenReceiverInterface(_to).onERC721Received(msg.sender, _from, _tokenId, "");
            require(retval == 0x150b7a02);
        }
    }
    
    //-------------------------------------------------------------------------
    /// @notice Transfers ownership of AAC #`_tokenId` from `_from` to `_to`
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, checks if
    ///  `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `0x150b7a02`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param _data Additional data with no pre-specified format
    //-------------------------------------------------------------------------
    function safeTransferFrom(
        address _from, 
        address _to, 
        uint256 _tokenId, 
        bytes _data
    ) external mustExist(_tokenId) payable {
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
            bytes4 retval = TokenReceiverInterface(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            require(retval == 0x150b7a02);
        }
    }

    //-------------------------------------------------------------------------
    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    //-------------------------------------------------------------------------
    function transferFrom(
        address _from, 
        address _to, 
        uint256 _tokenId
    ) external mustExist(_tokenId) payable {
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


//-----------------------------------------------------------------------------
/// @title Ownable
/// @dev The Ownable contract has an owner address, and provides basic 
///  authorization control functions, this simplifies the implementation of
///  "user permissions".
//-----------------------------------------------------------------------------
contract Ownable {
    //-------------------------------------------------------------------------
    /// @dev Emits when owner address changes by any mechanism.
    //-------------------------------------------------------------------------
    event OwnershipTransfer (address previousOwner, address newOwner);
    
    // Wallet address that can sucessfully execute onlyOwner functions
    address owner;
    
    //-------------------------------------------------------------------------
    /// @dev Sets the owner of the contract to the sender account.
    //-------------------------------------------------------------------------
    constructor() public {
        owner = msg.sender;
        emit OwnershipTransfer(address(0), owner);
    }

    //-------------------------------------------------------------------------
    /// @dev Throws if called by any account other than `owner`.
    //-------------------------------------------------------------------------
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    //-------------------------------------------------------------------------
    /// @notice Transfer control of the contract to a newOwner.
    /// @dev Throws if `_newOwner` is zero address.
    /// @param _newOwner The address to transfer ownership to.
    //-------------------------------------------------------------------------
    function transferOwnership(address _newOwner) public onlyOwner {
        // for safety, new owner parameter must not be 0
        require (_newOwner != address(0));
        // define local variable for old owner
        address oldOwner = owner;
        // set owner to new owner
        owner = _newOwner;
        // emit ownership transfer event
        emit OwnershipTransfer(oldOwner, _newOwner);
    }
}


//-----------------------------------------------------------------------------
/// @title AAC Interface Support
//-----------------------------------------------------------------------------
contract AacInterfaceSupport {
    // mapping of all possible interfaces to whether they are supported
    mapping (bytes4 => bool) interfaceIdToIsSupported;
    
    //-------------------------------------------------------------------------
    /// @notice AacInterfaceSupport constructor. Sets to true interfaces
    ///  supported at launch.
    //-------------------------------------------------------------------------
    constructor () public {
        // supports ERC-165
        interfaceIdToIsSupported[0x01ffc9a7] = true;
        // supports ERC-721
        interfaceIdToIsSupported[0x80ac58cd] = true;
        // supports ERC-721 Enumeration
        interfaceIdToIsSupported[0x780e9d63] = true;
        /* OPTIONAL. WILL REQUIRE A JSON FILE STORED AT A URL.
        // supports ERC-721 Metadata
        interfaceIdToIsSupported[0x5b5e139f] = true;
        */
    }

    //-------------------------------------------------------------------------
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    //-------------------------------------------------------------------------
    function supportsInterface(
        bytes4 interfaceID
    ) external view returns (bool) {
        if(interfaceID == 0xffffffff) {
            return false;
        } else {
            return interfaceIdToIsSupported[interfaceID];
        }
    }
}


//-----------------------------------------------------------------------------
/// @title PLAY Token Interface
//-----------------------------------------------------------------------------
interface PlayInterface {
    //-------------------------------------------------------------------------
    /// @notice Get the number of PLAY tokens owned by `tokenOwner`.
    /// @dev Throws if trying to query the zero address.
    /// @param tokenOwner The PLAY token owner.
    /// @return The number of PLAY tokens owned by `tokenOwner` (in pWei).
    //-------------------------------------------------------------------------
    function balanceOf(address tokenOwner) external view returns (uint);
    
    //-------------------------------------------------------------------------
    /// @notice Send `(tokens/1000000000000000000).fixed(0,18)` PLAY to `to`,
    ///  then lock for `numberOfYears` years.
    /// @dev Throws if amount to send is zero. Throws if `msg.sender` has
    ///  insufficient balance for transfer. Throws if `to` is the zero
    ///  address. Emits transfer and lock events.
    /// @param to The address to where PLAY is being sent and locked.
    /// @param numberOfYears The number of years the tokens will be locked.
    /// @param tokens The number of tokens to send (in pWei).
    //-------------------------------------------------------------------------
    function transferAndLock(
        address to, 
        uint numberOfYears, 
        uint tokens
    ) external;
}


//-----------------------------------------------------------------------------
/// @title AAC Creation
//-----------------------------------------------------------------------------
contract AacCreation is Ownable, AacTransfers, AacInterfaceSupport {
    //-------------------------------------------------------------------------
    /// @dev Link emits when an empty AAC gets .
    ///  This event emits when AACs are created (`from` == 0) and destroyed
    ///  (`to` == 0). At the time of any transfer, the approved address
    ///  for that AAC (if any) is reset to address(0).
    //-------------------------------------------------------------------------
    event Link(uint _oldUid, uint _newUid);

    // PLAY needed to mint one AAC (in pWei)
    uint public priceToMint = 1000 * 10**18;
    // Buffer added to the front of every AAC at time of creation. AACs with a
    //  uid greater than the buffer are guaranteed to be unlinked.
    uint constant uidBuffer = 100000000000000000; // 17 zeroes
    // contract address for the PLAY token.
    address playContract = 0xe12e918f3E7aaEF831bac1D1B5Fc236E2C771100;
    // Contract object to interface with
    PlayInterface play = PlayInterface(playContract);

    //-------------------------------------------------------------------------
    /// @notice Change the number of PLAY tokens needed to mint a new AAC (in
    ///  pWei).
    /// @dev Throws if `_newPrice` is zero.
    /// @param _newPrice The new price to mint (in pWei)
    //-------------------------------------------------------------------------
    function changeAacPrice(uint _newPrice) external onlyOwner {
        priceToMint = _newPrice;
    }

    //-------------------------------------------------------------------------
    //-------------------------------------------------------------------------
    function mint() external {
        require(play.balanceOf(msg.sender) >= priceToMint);

        uint uid = uidBuffer + aacArray.length;
        uint index = aacArray.push(AAC(msg.sender, uid, block.timestamp, 0, ""));
        uidToAacIndex[uid] = index - 1;

        play.transferAndLock (owner, 2, priceToMint);

        emit Transfer(0, msg.sender, uid);
    }


    //-------------------------------------------------------------------------
    //-------------------------------------------------------------------------
    function mintAndSend(address _to) external {
        require(play.balanceOf(msg.sender) >= priceToMint);

        uint uid = uidBuffer + aacArray.length;
        uint index = aacArray.push(AAC(_to, uid, block.timestamp, 0, ""));
        uidToAacIndex[uid] = index - 1;

        play.transferAndLock (owner, 2, priceToMint);

        emit Transfer(0, _to, uid);
    }

    //-------------------------------------------------------------------------
    //-------------------------------------------------------------------------
    function link(
        bytes7 _newUid, 
        uint _aacId, 
        bytes _publicData
    ) external mustExist(_aacId) {
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

    //-------------------------------------------------------------------------
    //-------------------------------------------------------------------------
    function getAac(uint _uid) 
        external
        view 
        mustExist(_uid) 
        returns (address, uint, uint, uint, bytes) 
    {
        AAC memory aac = aacArray[uidToAacIndex[_uid]];
        return(aac.owner, aac.uid, aac.timestamp, aac.exp, aac.publicData);
    }
}