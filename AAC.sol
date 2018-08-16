pragma solidity ^0.4.24;

//-----------------------------------------------------------------------------
/// @title AAC Ownership
/// @notice defines AAC ownership-tracking structures and view functions.
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
        // toy data
        bytes toyData;
    }

    // Array containing all AACs. The first element in aacArray returns invalid
    AAC[] aacArray;
    // Mapping containing all UIDs tracked by this contract. Valid UIDs map to
    //  index numbers, invalid UIDs map to 0.
    mapping (uint => uint) uidToAacIndex;
    
    //-------------------------------------------------------------------------
    /// @dev Throws if AAC #`_tokenId` isn't tracked by the AAC Array.
    //-------------------------------------------------------------------------
    modifier mustExist(uint _tokenId) {
        require (uidToAacIndex[_tokenId] != 0, "Invalid AAC UID");
        _;
    }

    //-------------------------------------------------------------------------
    /// @dev Throws if AAC #`_tokenId` isn't owned by sender.
    //-------------------------------------------------------------------------
    modifier mustOwn(uint _tokenId) {
        require (ownerOf(_tokenId) == msg.sender, "Must be owner of AAC");
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
        require (
            aacArray[uidToAacIndex[_tokenId]].owner != 0, 
            "AAC has no owner"
        );
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
        require (_owner != 0, "Cannot query the zero address");
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
        require(aacsOwned > 0, "No owned AACs");
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
        require (_index > 0 && _index < aacArray.length, "Invalid index");
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
        require(_owner != 0, "Cannot query the zero address");
        require(aacsOwned > 0, "No owned AACs");
        require(_index < aacsOwned, "Invalid index");
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
/// @notice Defines transfer functionality for AACs to transfer ownership.
///  Defines approval functionality for 3rd parties to enable transfers on
///  owners' behalf.
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
    //-------------------------------------------------------------------------
    modifier canOperate(uint _uid) {
        // sender must be owner of AAC #uid, or sender must be the approved
        // address of AAC #uid, or an authorized operator for AAC owner
        require (
            msg.sender == aacArray[uidToAacIndex[_uid]].owner ||
            msg.sender == idToApprovedAddress[_uid] ||
            operatorApprovals[aacArray[uidToAacIndex[_uid]].owner][msg.sender],
            "Not authorized to operate for this AAC"
        );
        _;
    }

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
        // msg.sender must be the current NFT owner, or an authorized operator
        //  of the current owner.
        require (
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "Not authorized to approve for this AAC"
        );
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
        require(_operator != msg.sender, "Operator cannot be sender");
        operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    
    //-------------------------------------------------------------------------
    /// @notice Get whether _operator is approved to manage all of _owner's
    ///  AACs
    /// @param _owner AAC Owner.
    /// @param _operator Address to check for approval.
    /// @return True if _operator is approved to manage all of _owner's AACs.
    //-------------------------------------------------------------------------
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
    ) external mustExist(_tokenId) payable canOperate(_tokenId) {
        address owner = ownerOf(_tokenId);
        // _from address must be current owner of the AAC
        require (_from == owner && _from != 0, "AAC not owned by '_from'");
        // _to address must not be zero address
        require (_to != 0, "Cannot transfer AAC to zero address");
        
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
            require(
                retval == 0x150b7a02, 
                "Destination contract not equipped to receive AACs"
            );
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
    ) external mustExist(_tokenId) payable canOperate(_tokenId) {
        address owner = ownerOf(_tokenId);
        // _from address must be current owner of the AAC
        require (_from == owner && _from != 0, "AAC not owned by '_from'");
        // _to address must not be zero address
        require (_to != 0, "Cannot transfer AAC to zero address");
        
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
            require(
                retval == 0x150b7a02,
                "Destination contract not equipped to receive AACs"
            );
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
        // sender must be the current owner, an authorized operator, or the
        //  approved address for the AAC
        require (
            msg.sender == owner || 
            isApprovedForAll(owner, msg.sender) || 
            msg.sender == idToApprovedAddress[_tokenId],
            "Not authorized to transfer this AAC"
        );
        // _from address must be current owner of the AAC
        require (_from == owner && _from != 0, "AAC not owned by '_from'");
        // _to address must not be zero address
        require (_to != 0, "Cannot transfer AAC to zero address");
        
        // clear approval
        idToApprovedAddress[_tokenId] = 0;
        // transfer ownership
        aacArray[uidToAacIndex[_tokenId]].owner = _to;

        emit Transfer(_from, _to, _tokenId);
    }
}


//-----------------------------------------------------------------------------
///@title ERC-20 function declarations
//-----------------------------------------------------------------------------
interface ERC20 {
    function transfer (
        address to, 
        uint tokens
    ) external returns (bool success);

    function transferFrom (
        address from, 
        address to, 
        uint tokens
    ) external returns (bool success);
}


//-----------------------------------------------------------------------------
/// @title External Token Handler
/// @notice Defines depositing and withdrawal of Ether and ERC-20-compliant
///  tokens into AACs.
//-----------------------------------------------------------------------------
contract ExternalTokenHandler is AacTransfers {
    // handles the balances of AACs for every ERC20 token address
    mapping (address => mapping(uint => uint)) externalTokenBalances;
    
    // UID value is 7 bytes. Max value is 2**56 - 1
    uint constant UID_MAX = 0xFFFFFFFFFFFFFF;

    //-------------------------------------------------------------------------
    /// @notice Deposit Ether from sender to approved AAC
    /// @dev Throws if Ether to deposit is zero. Throws if sender is not
    ///  approved to operate AAC #`toUid`. Throws if AAC #`toUid` is unlinked.
    ///  Throws if sender has insufficient balance for deposit.
    /// @param _toUid the AAC to deposit the Ether into
    //-------------------------------------------------------------------------
    function depositEther(uint _toUid) external payable canOperate(_toUid) {
        // Ether to deposit must be greater than zero
        require (msg.value > 0, "Cannot deposit zero Ether");
        // AAC must be linked
        require (_toUid < UID_MAX, "Invalid AAC. AAC not yet linked");
        // add amount to AAC's balance
        externalTokenBalances[address(this)][_toUid] += msg.value;
    }

    //-------------------------------------------------------------------------
    /// @notice Withdraw Ether from approved AAC to AAC's owner
    /// @dev Throws if Ether to withdraw is zero. Throws if sender is not an
    ///  approved operator for AAC #`_fromUid`. Throws if AAC #`_fromUid` has
    ///  insufficient balance to withdraw.
    /// @param _fromUid the AAC to withdraw the Ether from
    /// @param _amount the amount of Ether to withdraw (in Wei)
    //-------------------------------------------------------------------------
    function withdrawEther(
        uint _fromUid, 
        uint _amount
    ) external canOperate(_fromUid) {
        // Ether to withdraw must be greater than zero
        require (_amount > 0, "Cannot withdraw zero Ether");
        // AAC must have sufficient Ether balance
        require (
            externalTokenBalances[address(this)][_fromUid] >= _amount,
            "Insufficient Ether to withdraw"
        );
        // subtract amount from AAC's balance
        externalTokenBalances[address(this)][_fromUid] -= _amount;
        // call transfer function
        ownerOf(_fromUid).transfer(_amount);
    }

    //-------------------------------------------------------------------------
    /// @notice Withdraw Ether from approved AAC and send to '_to'
    /// @dev Throws if Ether to transfer is zero. Throws if sender is not an
    ///  approved operator for AAC #`to_fromUidUid`. Throws if AAC #`_fromUid`
    ///  has insufficient balance to withdraw.
    /// @param _fromUid the AAC to withdraw and send the Ether from
    /// @param _to the address to receive the transferred Ether
    /// @param _amount the amount of Ether to withdraw (in Wei)
    //-------------------------------------------------------------------------
    function transferEther(
        uint _fromUid,
        address _to,
        uint _amount
    ) external canOperate(_fromUid) {
        // Ether to transfer must be greater than zero
        require (_amount > 0, "Cannot transfer zero Ether");
        // AAC must have sufficient Ether balance
        require (
            externalTokenBalances[address(this)][_fromUid] >= _amount,
            "Insufficient Ether to transfer"
        );
        // subtract amount from AAC's balance
        externalTokenBalances[address(this)][_fromUid] -= _amount;
        // call transfer function
        _to.transfer(_amount);
    }

    //-------------------------------------------------------------------------
    /// @notice Deposit ERC-20 tokens from sender to approved AAC
    /// @dev This contract address must be an authorized spender for sender.
    ///  Throws if tokens to deposit is zero. Throws if sender is not an
    ///  approved operator for AAC #`toUid`. Throws if AAC #`toUid` is
    ///  unlinked. Throws if this contract address has insufficient allowance
    ///  for transfer. Throws if sender has insufficient balance for deposit.
    ///  Throws if tokenAddress has no transferFrom function.
    /// @param _tokenAddress the ERC-20 contract address
    /// @param _toUid the AAC to deposit the ERC-20 tokens into
    /// @param _tokens the number of tokens to deposit
    //-------------------------------------------------------------------------
    function depositERC20 (
        address _tokenAddress, 
        uint _toUid, 
        uint _tokens
    ) external canOperate(_toUid) {
        // tokens to deposit must be greater than zero
        require (_tokens > 0, "Cannot deposit zero tokens");
        // AAC must be linked
        require (_toUid < UID_MAX, "Invalid AAC. AAC not yet linked");
        // initialize token contract
        ERC20 tokenContract = ERC20(_tokenAddress);
        // add amount to AAC's balance
        externalTokenBalances[_tokenAddress][_toUid] += _tokens;

        // call transferFrom function from token contract
        tokenContract.transferFrom(msg.sender, address(this), _tokens);
    }

    //-------------------------------------------------------------------------
    /// @notice Deposit ERC-20 tokens from '_to' to approved AAC
    /// @dev This contract address must be an authorized spender for '_from'.
    ///  Throws if tokens to deposit is zero. Throws if sender is not an
    ///  approved operator for AAC #`toUid`. Throws if AAC #`toUid` is
    ///  unlinked. Throws if this contract address has insufficient allowance
    ///  for transfer. Throws if sender has insufficient balance for deposit.
    ///  Throws if tokenAddress has no transferFrom function.
    /// @param _tokenAddress the ERC-20 contract address
    /// @param _from the address sending ERC-21 tokens to deposit
    /// @param _toUid the AAC to deposit the ERC-20 tokens into
    /// @param _tokens the number of tokens to deposit
    //-------------------------------------------------------------------------
    function depositERC20From (
        address _tokenAddress,
        address _from, 
        uint _toUid, 
        uint _tokens
    ) external canOperate(_toUid) {
        // tokens to deposit must be greater than zero
        require (_tokens > 0, "Cannot deposit zero tokens");
        // AAC must be linked
        require (_toUid < UID_MAX, "Invalid AAC. AAC not yet linked");
        // initialize token contract
        ERC20 tokenContract = ERC20(_tokenAddress);
        // add amount to AAC's balance
        externalTokenBalances[_tokenAddress][_toUid] += _tokens;

        // call transferFrom function from token contract
        tokenContract.transferFrom(_from, address(this), _tokens);
    }

    //-------------------------------------------------------------------------
    /// @notice Withdraw ERC-20 tokens from approved AAC to AAC's owner
    /// @dev Throws if tokens to withdraw is zero. Throws if sender is not an
    ///  approved operator for AAC #`_fromUid`. Throws if AAC #`_fromUid` has
    ///  insufficient balance to withdraw. Throws if tokenAddress has no
    ///  transfer function.
    /// @param tokenAddress the ERC-20 contract address
    /// @param fromUid the AAC to withdraw the ERC-20 tokens from
    /// @param tokens the number of tokens to withdraw
    //-------------------------------------------------------------------------
    function withdrawERC20 (
        address _tokenAddress, 
        uint _fromUid, 
        uint _tokens
    ) external canOperate(_fromUid) {
        // tokens to withdraw must be greater than zero.
        require (_tokens > 0, "Cannot withdraw zero tokens");
        // AAC must have sufficient token balance
        require (
            externalTokenBalances[_tokenAddress][_fromUid] >= _tokens,
            "insufficient tokens to withdraw"
        );
        // initialize token contract
        ERC20 tokenContract = ERC20(_tokenAddress);
        // subtract amount from AAC's balance
        externalTokenBalances[_tokenAddress][_fromUid] -= _tokens;
        
        // call transfer function from token contract
        tokenContract.transfer(ownerOf(_fromUid), _tokens);
    }

    //-------------------------------------------------------------------------
    /// @notice Transfer ERC-20 tokens from your AAC to `_to`
    /// @dev Throws if tokens to transfer is zero. Throws if sender is not an
    ///  approved operator for AAC #`_fromUid`. Throws if AAC #`_fromUid` has
    ///  insufficient balance to transfer. Throws if tokenAddress has no
    ///  transfer function.
    /// @param tokenAddress the ERC-20 contract address
    /// @param fromUid the AAC to withdraw the ERC-20 tokens from
    /// @param to the wallet address to send the ERC-20 tokens
    /// @param tokens the number of tokens to withdraw
    //-------------------------------------------------------------------------
    function transferERC20 (
        address _tokenAddress, 
        uint _fromUid, 
        address _to, 
        uint _tokens
    ) external canOperate(_fromUid) {
        // tokens to transfer must be greater than zero.
        require (_tokens > 0, "Cannot withdraw zero tokens");
        // AAC must have sufficient token balance
        require (
            externalTokenBalances[_tokenAddress][_fromUid] >= _tokens,
            "insufficient tokens to withdraw"
        );
        // initialize token contract
        ERC20 tokenContract = ERC20(_tokenAddress);
        // subtract amount from AAC's balance
        externalTokenBalances[_tokenAddress][_fromUid] -= _tokens;
        
        // call transfer function from token contract
        tokenContract.transfer(_to, _tokens);
    }

    //-------------------------------------------------------------------------
    /// @notice Get external token balance for tokens deposited into AAC
    ///  #`_uid`.
    /// @dev To query Ether, use THIS CONTRACT'S address as '_tokenAddress'.
    /// @param _uid Owner of the tokens to query
    /// @param _tokenAddress Token creator contract address 
    //-------------------------------------------------------------------------
    function getExternalTokenBalance(
        uint _uid, 
        address _tokenAddress
    ) external view returns (uint) {
        return externalTokenBalances[_tokenAddress][_uid];
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
        require(
            msg.sender == owner, 
            "Function can only be called by contract owner"
        );
        _;
    }

    //-------------------------------------------------------------------------
    /// @notice Transfer control of the contract to a newOwner.
    /// @dev Throws if `_newOwner` is zero address.
    /// @param _newOwner The address to transfer ownership to.
    //-------------------------------------------------------------------------
    function transferOwnership(address _newOwner) public onlyOwner {
        // for safety, new owner parameter must not be 0
        require (
            _newOwner != address(0),
            "New owner address cannot be zero"
        );
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
/// @notice Defines supported interfaces for ERC-721 wallets to query
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
        // supports ERC-721 Metadata
        interfaceIdToIsSupported[0x5b5e139f] = true;
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
    /// @notice Send `(tokens/1000000000000000000).fixed(0,18)` PLAY from 
    ///  `from` to `to`, then lock for `numberOfYears` years.
    /// @dev Throws if amount to send is zero. Throws if `msg.sender` has
    ///  insufficient allowance for transfer. Throws if `from` has 
    ///  insufficient balance for transfer. Throws if `to` is the zero
    ///  address. Emits transfer and lock events.
    /// @param from The token owner whose PLAY is being sent. Sender must be
    ///  an approved spender.
    /// @param to The address to where PLAY is being sent and locked.
    /// @param tokens The number of tokens to send (in pWei).
    //-------------------------------------------------------------------------
    function transferFromAndLock(
        address from, 
        address to, 
        uint numberOfYears, 
        uint tokens
    ) external;
}


//-----------------------------------------------------------------------------
/// @title AAC Creation
/// @notice Defines new AAC creation (minting) and AAC linking to RFID-enabled
///  physical objects.
//-----------------------------------------------------------------------------
contract AacCreation is Ownable, ExternalTokenHandler, AacInterfaceSupport {
    //-------------------------------------------------------------------------
    /// @dev Link emits when an empty AAC gets assigned to a valid RFID UID.
    //-------------------------------------------------------------------------
    event Link(uint _oldUid, uint _newUid);

    // PLAY needed to mint one AAC (in pWei)
    uint public priceToMint = 1000 * 10**18;
    // Buffer added to the front of every AAC at time of creation. AACs with a
    //  uid greater than the buffer are guaranteed to be unlinked.
    uint constant uidBuffer = 0x0100000000000000; // 14 zeroes
    // PLAY Token Contract object to interface with.
    PlayInterface play = PlayInterface(0x1A3E0766ff1326D295B2D2213618BFB9d07FCC30);

    //-------------------------------------------------------------------------
    /// @notice Update PLAY Token contract variable with new contract address.
    /// @dev Throws if `_newAddress` is the zero address.
    /// @param _newAddress Updated contract address.
    //-------------------------------------------------------------------------
    function updatePlayTokenContract(address _newAddress) external onlyOwner {
        play = PlayInterface(_newAddress);
    }

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
    /// @notice Send and lock PLAY to mint a new empty AAC for yourself.
    /// @dev Sender must have approved this contract address as an authorized
    ///  spender with at least "priceToMint" PLAY. Throws if the sender has
    ///  insufficient PLAY. Throws if sender has not granted this contract's
    ///  address sufficient allowance.
    //-------------------------------------------------------------------------
    function mint() external {
        play.transferFromAndLock (msg.sender, owner, 2, priceToMint);

        uint uid = uidBuffer + aacArray.length;
        uint index = aacArray.push(AAC(msg.sender, uid, block.timestamp, 0, ""));
        uidToAacIndex[uid] = index - 1;

        emit Transfer(0, msg.sender, uid);
    }


    //-------------------------------------------------------------------------
    /// @notice Send and lock PLAY to mint a new empty AAC for 'to'.
    /// @dev Sender must have approved this contract address as an authorized
    ///  spender with at least "priceToMint" PLAY. Throws if the sender has
    ///  insufficient PLAY. Throws if sender has not granted this contract's
    ///  address sufficient allowance.
    /// @param _to The address to deduct PLAY Tokens from and send new AAC to.
    //-------------------------------------------------------------------------
    function mintAndSend(address _to) external {
        play.transferFromAndLock (msg.sender, owner, 2, priceToMint);

        uint uid = uidBuffer + aacArray.length;
        uint index = aacArray.push(AAC(_to, uid, block.timestamp, 0, ""));
        uidToAacIndex[uid] = index - 1;

        emit Transfer(0, _to, uid);
    }

    //-------------------------------------------------------------------------
    /// @notice Change AAC #`_aacId` to AAC #`_newUid`. Writes any data passed
    ///  through '_publicData' into the AAC's public data field.
    /// @dev Throws if AAC #`_aacId` does not exist. Throws if AAC is not
    ///  owned by sender. Throws if '_aacId' is smaller than 8 bytes. Throws
    ///  if '_newUid' is bigger than 7 bytes. Throws if '_newUid' is zero.
    ///  Throws if '_newUid' is already taken.
    /// @param _newUid The UID of the RFID chip to link to the AAC
    /// @param _aacId The UID of the empty AAC to link
    /// @param _publicData A byte string of data to attach to the AAC
    //-------------------------------------------------------------------------
    function link(
        bytes7 _newUid, 
        uint _aacId, 
        bytes _data
    ) external mustExist(_aacId) {
        AAC storage aac = aacArray[uidToAacIndex[_aacId]];
        // sender must own AAC
        require (msg.sender == aac.owner, "AAC not owned by sender");
        // _aacId must be an empty AAC
        require (_aacId > uidBuffer, "AAC already linked");
        // _newUid field cannot be empty or greater than 7 bytes
        require (_newUid > 0 && uint(_newUid) < UID_MAX, "Invalid new UID");
        // an AAC with the new UID must not currently exist
        require (uidToAacIndex[uint(_newUid)] == 0, "New UID already exists");

        // set new UID's mapping to index to old UID's mapping
        uidToAacIndex[uint(_newUid)] = uidToAacIndex[_aacId];
        // reset old UID's mapping to index
        uidToAacIndex[_aacId] = 0;
        // set AAC's UID to new UID
        aac.uid = uint(_newUid);
        // set any data
        aac.toyData = _data;

        emit Link(_aacId, uint(_newUid));
    }

    //-------------------------------------------------------------------------
    /// @notice Change AAC #`_aacId` to AAC #`_newUid`. Writes any data passed
    ///  through '_publicData' into the AAC's public data field.
    /// @dev Throws if AAC #`_aacId` does not exist. Throws if AAC is not
    ///  owned by sender. Throws if '_aacId' is smaller than 8 bytes. Throws
    ///  if '_newUid' is bigger than 7 bytes. Throws if '_newUid' is zero.
    ///  Throws if '_newUid' is already taken. Throws if sender is not the
    ///  approved address of AAC #`from` or an authorized operator for `to`.
    /// @param _owner The owner of AAC #`_aacId`. Sender must be approved.
    /// @param _newUid The UID of the RFID chip to link to the AAC
    /// @param _aacId The UID of the empty AAC to link
    /// @param _publicData A byte string of data to attach to the AAC
    //-------------------------------------------------------------------------
    function linkFrom(
        address _owner,
        bytes7 _newUid, 
        uint _aacId, 
        bytes _data
    ) external mustExist(_aacId) {
        AAC storage aac = aacArray[uidToAacIndex[_aacId]];
        // sender must own AAC
        require (_owner == aac.owner, "AAC not owned by sender");
        // _aacId must be an empty AAC
        require (_aacId > uidBuffer, "AAC already linked");
        // _newUid field cannot be empty or greater than 7 bytes
        require (_newUid > 0 && uint(_newUid) < UID_MAX, "Invalid new UID");
        // an AAC with the new UID must not currently exist
        require (uidToAacIndex[uint(_newUid)] == 0, "New UID already exists");
        // msg.sender must be the approved address of AAC #uid, or an authorized
        //  operator for from
        require (
            msg.sender == idToApprovedAddress[_aacId] ||
            operatorApprovals[_owner][msg.sender] == true,
            "Not authorized to link this AAC"
        );
        // set new UID's mapping to index to old UID's mapping
        uidToAacIndex[uint(_newUid)] = uidToAacIndex[_aacId];
        // reset old UID's mapping to index
        uidToAacIndex[_aacId] = 0;
        // set AAC's UID to new UID
        aac.uid = uint(_newUid);
        // set any data
        aac.toyData = _data;

        emit Link(_aacId, uint(_newUid));
    }
}

//-----------------------------------------------------------------------------
/// @title AAC Interface
/// @notice Interface for highest-level AAC getters
//-----------------------------------------------------------------------------
contract AacInterface is AacCreation {
    // URL Containing AAC metadata
    string metadataUrl = "https://blok.party/aac/";

    //-------------------------------------------------------------------------
    /// @notice Change old metadata URL to `_newUrl`
    /// @dev Throws if new URL is empty
    /// @param _newUrl The new URL containing AAC metadata
    //-------------------------------------------------------------------------
    function updateMetadataUrl(string _newUrl) external onlyOwner {
        require(bytes(_newUrl).length > 0, "New URL parameter was empty");
        metadataUrl = _newUrl;
    }

    //-------------------------------------------------------------------------
    /// @notice Gets all public info for AAC #`_uid`.
    /// @dev Throws if AAC #`_uid` does not exist.
    /// @param _uid the UID of the AAC to view.
    /// @return AAC owner, AAC UID, Creation Timestamp, Experience, and Public
    ///  Data.
    //-------------------------------------------------------------------------
    function getAac(uint _uid) 
        external
        view 
        mustExist(_uid) 
        returns (address, uint, uint, uint, bytes) 
    {
        AAC memory aac = aacArray[uidToAacIndex[_uid]];
        return(aac.owner, aac.uid, aac.timestamp, aac.exp, aac.toyData);
    }

    //-------------------------------------------------------------------------
    /// @notice A descriptive name for a collection of NFTs in this contract
    //-------------------------------------------------------------------------
    function name() external pure returns (string) {
        return "Authentic Asset Certificates";
    }

    //-------------------------------------------------------------------------
    /// @notice An abbreviated name for NFTs in this contract
    //-------------------------------------------------------------------------
    function symbol() external pure returns (string) { return "AAC"; }

    //-------------------------------------------------------------------------
    /// @notice A distinct URL for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT.
    ///  If:
    ///  * The URI is a URL
    ///  * The URL is accessible
    ///  * The URL points to a valid JSON file format (ECMA-404 2nd ed.)
    ///  * The JSON base element is an object
    ///  then these names of the base element SHALL have special meaning:
    ///  * "name": A string identifying the item to which `_tokenId` grants
    ///    ownership
    ///  * "description": A string detailing the item to which `_tokenId` grants
    ///    ownership
    ///  * "image": A URI pointing to a file of image/* mime type representing
    ///    the item to which `_tokenId` grants ownership
    ///  Wallets and exchanges MAY display this to the end user.
    ///  Consider making any images at a width between 320 and 1080 pixels and
    ///  aspect ratio between 1.91:1 and 4:5 inclusive.
    /// @param _tokenId The AAC whose metadata address is being queried
    //-------------------------------------------------------------------------
    function tokenURI(uint _tokenId) 
        external 
        view 
        returns (string) 
    {
        // convert AAC UID to a 14 character long string of character bytes
        bytes memory uidString = intToBytes(_tokenId);
        // declare new string of bytes with combined length of url and uid 
        bytes memory fullUrlBytes = new bytes(bytes(metadataUrl).length + uidString.length);
        // copy URL string and uid string into new string
        uint counter = 0;
        for (uint i = 0; i < bytes(metadataUrl).length; i++) {
            fullUrlBytes[counter++] = bytes(metadataUrl)[i];
        }
        for (i = 0; i < uidString.length; i++) {
            fullUrlBytes[counter++] = uidString[i];
        }
        // return full URL
        return string(fullUrlBytes);
    }
    
    //-------------------------------------------------------------------------
    /// @notice Convert int to 14 character bytes
    //-------------------------------------------------------------------------
    function intToBytes(uint _tokenId) 
        private 
        pure 
        returns (bytes) 
    {
        // convert int to bytes32
        bytes32 x = bytes32(_tokenId);
        
        // convert each byte into two, and assign each byte a hex digit
        bytes memory uidBytes64 = new bytes(64);
        for (uint i = 0; i < 32; i++) {
            byte b = byte(x[i]);
            byte hi = byte(uint8(b) / 16);
            byte lo = byte(uint8(b) - 16 * uint8(hi));
            uidBytes64[i*2] = char(hi);
            uidBytes64[i*2+1] = char(lo);
        }
        
        // reduce size to last 14 chars (7 bytes)
        bytes memory uidBytes = new bytes(14);
        for (i = 0; i < 14; ++i) {
            uidBytes[i] = uidBytes64[i + 50];
        }
        return uidBytes;
    }
    
    //-------------------------------------------------------------------------
    /// @notice Convert byte to UTF-8-encoded hex character
    //-------------------------------------------------------------------------
    function char(byte b) private pure returns (byte c) {
        if (b < 10) return byte(uint8(b) + 0x30);
        else return byte(uint8(b) + 0x57);
    }
}