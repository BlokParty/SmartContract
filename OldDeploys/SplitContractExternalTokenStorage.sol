pragma solidity ^0.4.24;

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

/// @title ERC-721 Non-Fungible Token Standard
interface ERC721 {
    function ownerOf(uint256 _tokenId) external view returns (address);
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}


//-----------------------------------------------------------------------------
/// @title External Token Handler
/// @notice Defines depositing and withdrawal of Ether and ERC-20-compliant
///  tokens into TOY Tokens.
//-----------------------------------------------------------------------------
contract ExternalTokenHandler {
    // handles the balances of TOY Tokens for every ERC20 token address
    mapping (address => mapping(uint => uint)) externalTokenBalances;
    
    // UID value is 7 bytes. Max value is 2**56 - 1
    uint constant UID_MAX = 0xFFFFFFFFFFFFFF;

    ERC721 ToyContract = ERC721();

    modifier canOperate(uint _uid) {
        require (
            msg.sender == ToyContract.ownerOf(_uid) ||
            msg.sender == ToyContract.getApproved(_uid) ||
            ToyContract.isApprovedForAll[ToyContract.ownerOf(_uid)][msg.sender],
            "Sender is not authorized to operate this TOY Token"
        );
        _;
    }

    modifier notZero(uint _param) {
        require(_param != 0, "Parameter cannot be zero");
        _;
    }

    //-------------------------------------------------------------------------
    /// @notice Deposit Ether from sender to approved TOY Token
    /// @dev Throws if Ether to deposit is zero. Throws if sender is not
    ///  approved to operate TOY Token #`toUid`. Throws if TOY Token #`toUid`
    ///  is unlinked. Throws if sender has insufficient balance for deposit.
    /// @param _toUid the TOY Token to deposit the Ether into
    //-------------------------------------------------------------------------
    function depositEther(uint _toUid) 
        external 
        payable 
        canOperate(_toUid)
        notZero(msg.value)
    {
        // TOY Token must be linked
        require (
            _toUid < UID_MAX, 
            "Invalid TOY Token. TOY Token not yet linked"
        );
        // add amount to TOY Token's balance
        externalTokenBalances[address(this)][_toUid] += msg.value;
    }

    //-------------------------------------------------------------------------
    /// @notice Withdraw Ether from approved TOY Token to TOY Token's owner
    /// @dev Throws if Ether to withdraw is zero. Throws if sender is not an
    ///  approved operator for TOY Token #`_fromUid`. Throws if TOY Token 
    ///  #`_fromUid` has insufficient balance to withdraw.
    /// @param _fromUid the TOY Token to withdraw the Ether from
    /// @param _amount the amount of Ether to withdraw (in Wei)
    //-------------------------------------------------------------------------
    function withdrawEther(
        uint _fromUid, 
        uint _amount
    ) external canOperate(_fromUid) notZero(_amount) {
        // TOY Token must have sufficient Ether balance
        require (
            externalTokenBalances[address(this)][_fromUid] >= _amount,
            "Insufficient Ether to withdraw"
        );
        // subtract amount from TOY Token's balance
        externalTokenBalances[address(this)][_fromUid] -= _amount;
        // call transfer function
        ToyContract.ownerOf(_fromUid).transfer(_amount);
    }

    //-------------------------------------------------------------------------
    /// @notice Withdraw Ether from approved TOY Token and send to '_to'
    /// @dev Throws if Ether to transfer is zero. Throws if sender is not an
    ///  approved operator for TOY Token #`to_fromUidUid`. Throws if TOY Token
    ///  #`_fromUid` has insufficient balance to withdraw.
    /// @param _fromUid the TOY Token to withdraw and send the Ether from
    /// @param _to the address to receive the transferred Ether
    /// @param _amount the amount of Ether to withdraw (in Wei)
    //-------------------------------------------------------------------------
    function transferEther(
        uint _fromUid,
        address _to,
        uint _amount
    ) external canOperate(_fromUid) notZero(_amount) {
        // TOY Token must have sufficient Ether balance
        require (
            externalTokenBalances[address(this)][_fromUid] >= _amount,
            "Insufficient Ether to transfer"
        );
        // subtract amount from TOY Token's balance
        externalTokenBalances[address(this)][_fromUid] -= _amount;
        // call transfer function
        _to.transfer(_amount);
    }

    //-------------------------------------------------------------------------
    /// @notice Deposit ERC-20 tokens from sender to approved TOY Token
    /// @dev This contract address must be an authorized spender for sender.
    ///  Throws if tokens to deposit is zero. Throws if sender is not an
    ///  approved operator for TOY Token #`toUid`. Throws if TOY Token #`toUid`
    ///  is unlinked. Throws if this contract address has insufficient
    ///  allowance for transfer. Throws if sender has insufficient balance for 
    ///  deposit. Throws if tokenAddress has no transferFrom function.
    /// @param _tokenAddress the ERC-20 contract address
    /// @param _toUid the TOY Token to deposit the ERC-20 tokens into
    /// @param _tokens the number of tokens to deposit
    //-------------------------------------------------------------------------
    function depositERC20 (
        address _tokenAddress, 
        uint _toUid, 
        uint _tokens
    ) external canOperate(_toUid) notZero(_tokens) {
        // TOY Token must be linked
        require (_toUid < UID_MAX, "Invalid TOY Token. TOY Token not yet linked");
        // initialize token contract
        ERC20 tokenContract = ERC20(_tokenAddress);
        // add amount to TOY Token's balance
        externalTokenBalances[_tokenAddress][_toUid] += _tokens;

        // call transferFrom function from token contract
        tokenContract.transferFrom(msg.sender, address(this), _tokens);
    }

    //-------------------------------------------------------------------------
    /// @notice Deposit ERC-20 tokens from '_to' to approved TOY Token
    /// @dev This contract address must be an authorized spender for '_from'.
    ///  Throws if tokens to deposit is zero. Throws if sender is not an
    ///  approved operator for TOY Token #`toUid`. Throws if TOY Token #`toUid`
    ///  is unlinked. Throws if this contract address has insufficient
    ///  allowance for transfer. Throws if sender has insufficient balance for
    ///  deposit. Throws if tokenAddress has no transferFrom function.
    /// @param _tokenAddress the ERC-20 contract address
    /// @param _from the address sending ERC-21 tokens to deposit
    /// @param _toUid the TOY Token to deposit the ERC-20 tokens into
    /// @param _tokens the number of tokens to deposit
    //-------------------------------------------------------------------------
    function depositERC20From (
        address _tokenAddress,
        address _from, 
        uint _toUid, 
        uint _tokens
    ) external canOperate(_toUid) notZero(_tokens) {
        // TOY Token must be linked
        require (
            _toUid < UID_MAX, 
            "Invalid TOY Token. TOY Token not yet linked"
        );
        // initialize token contract
        ERC20 tokenContract = ERC20(_tokenAddress);
        // add amount to TOY Token's balance
        externalTokenBalances[_tokenAddress][_toUid] += _tokens;

        // call transferFrom function from token contract
        tokenContract.transferFrom(_from, address(this), _tokens);
    }

    //-------------------------------------------------------------------------
    /// @notice Withdraw ERC-20 tokens from approved TOY Token to TOY Token's
    ///  owner
    /// @dev Throws if tokens to withdraw is zero. Throws if sender is not an
    ///  approved operator for TOY Token #`_fromUid`. Throws if TOY Token 
    ///  #`_fromUid` has insufficient balance to withdraw. Throws if 
    ///  tokenAddress has no transfer function.
    /// @param _tokenAddress the ERC-20 contract address
    /// @param _fromUid the TOY Token to withdraw the ERC-20 tokens from
    /// @param _tokens the number of tokens to withdraw
    //-------------------------------------------------------------------------
    function withdrawERC20 (
        address _tokenAddress, 
        uint _fromUid, 
        uint _tokens
    ) external canOperate(_fromUid) notZero(_tokens) {
        // TOY Token must have sufficient token balance
        require (
            externalTokenBalances[_tokenAddress][_fromUid] >= _tokens,
            "insufficient tokens to withdraw"
        );
        // initialize token contract
        ERC20 tokenContract = ERC20(_tokenAddress);
        // subtract amount from TOY Token's balance
        externalTokenBalances[_tokenAddress][_fromUid] -= _tokens;
        
        // call transfer function from token contract
        tokenContract.transfer(ToyContract.ownerOf(_fromUid), _tokens);
    }

    //-------------------------------------------------------------------------
    /// @notice Transfer ERC-20 tokens from your TOY Token to `_to`
    /// @dev Throws if tokens to transfer is zero. Throws if sender is not an
    ///  approved operator for TOY Token #`_fromUid`. Throws if TOY Token 
    ///  #`_fromUid` has insufficient balance to transfer. Throws if 
    ///  tokenAddress has no transfer function.
    /// @param _tokenAddress the ERC-20 contract address
    /// @param _fromUid the TOY Token to withdraw the ERC-20 tokens from
    /// @param _to the wallet address to send the ERC-20 tokens
    /// @param _tokens the number of tokens to withdraw
    //-------------------------------------------------------------------------
    function transferERC20 (
        address _tokenAddress, 
        uint _fromUid, 
        address _to, 
        uint _tokens
    ) external canOperate(_fromUid) notZero(_tokens) {
        // TOY Token must have sufficient token balance
        require (
            externalTokenBalances[_tokenAddress][_fromUid] >= _tokens,
            "insufficient tokens to withdraw"
        );
        // initialize token contract
        ERC20 tokenContract = ERC20(_tokenAddress);
        // subtract amount from TOY Token's balance
        externalTokenBalances[_tokenAddress][_fromUid] -= _tokens;
        
        // call transfer function from token contract
        tokenContract.transfer(_to, _tokens);
    }

    //-------------------------------------------------------------------------
    /// @notice Get external token balance for tokens deposited into TOY Token
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