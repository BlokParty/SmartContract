pragma solidity ^0.4.24;

import "./ColorToken.sol";

//-----------------------------------------------------------------------------
// AAC Interface - ERC721-compliant view functions 
//-----------------------------------------------------------------------------
interface AACOwnership {
    function ownerOf(uint256 _tokenId) external view returns (address);
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(
        address _owner, 
        address _operator
    ) external view returns (bool);
}


//-----------------------------------------------------------------------------
/// @title AAC Interaction Contract
/// @notice Defines functions for depositing and withdrawing colored tokens
///  into AACs.
//-----------------------------------------------------------------------------
contract AACInteraction is ColorToken {

    event Deposit(
        address indexed from, 
        uint indexed to, 
        uint indexed colorIndex, 
        uint tokens
    );

    event Withdraw(
        uint indexed from,
        address indexed to,
        uint indexed colorIndex,
        uint tokens
    );

    // AAC contract to interface with
    AACOwnership aac;
    // UID value is 7 bytes. Max value is 2**56
    uint constant MAX_UID = 72057594037927936;

    //-------------------------------------------------------------------------
    /// @notice Set the address of the AAC interface to `aacAddress`.
    /// @dev Throws if aacAddress is the zero address.
    /// @param aacAddress The address of the AAC interface.
    //-------------------------------------------------------------------------
    function setAacContractAddress (address aacAddress) external onlyOwner {
        // aacAddress must not be zero address
        require (aacAddress != address(0));
        // initialize contract to aacAddress
        aac = AACOwnership(aacAddress);
    }

    //-------------------------------------------------------------------------
    /// @notice Deposit `(tokens/1000000000000000000).fixed(0,18)` colored 
    ///  tokens with index `colorIndex` into AAC #`uid`.
    /// @dev Throws if tokens to deposit is zero. Throws if colorIndex is
    ///  greater than number of colored tokens. Throws if `msg.sender` has
    ///  insufficient balance to deposit. Throws if `uid` is greater than
    ///  maximum UID value. Throws if sender is not the owner of AAC #`uid`
    ///  unless sender is the creator of the colored token.
    /// @param uid The Unique Identifier of the AAC receiving tokens.
    /// @param colorIndex The index of the color to spend.
    /// @param tokens The number of colored tokens to spend (in pWei).
    //-------------------------------------------------------------------------
    function deposit (uint colorIndex, uint uid, uint tokens) external {
        // tokens to deposit must be greater than 0
        require (tokens > 0);
        // colorIndex must be valid color
        require (colorIndex < coloredTokens.length);
        // sender must have sufficient colored token balance
        require (coloredTokens[colorIndex].balances[msg.sender] >= tokens);
        // uid must be a valid UID
        require (uid < MAX_UID);
        // msg.sender must be owner of AAC #uid
        require (
            msg.sender == aac.ownerOf(uid) ||
            msg.sender == coloredTokens[colorIndex].creator
        );
        // deduct colored tokens from 
        coloredTokens[colorIndex].balances[msg.sender] -= tokens;
        coloredTokens[colorIndex].balances[address(uid)] += tokens;
    }

    //-------------------------------------------------------------------------
    /// @notice Deposit `(tokens/1000000000000000000).fixed(0,18)` colored 
    ///  tokens with index `colorIndex` from `from` into AAC #`uid`.
    /// @dev Throws if tokens to deposit is zero. Throws if colorIndex is
    ///  greater than number of colored tokens. Throws if `msg.sender` has
    ///  insufficient balance to deposit. Throws if `uid` is greater than
    ///  maximum UID value. Throws if `from` is not the owner of AAC #`uid`.
    ///  Throws if sender is not the approved address of AAC #`uid` or an
    ///  authorized operator for `from`.
    /// @param from The address whose PLAY is being deposited.
    /// @param colorIndex The index of the colored token to deposit.
    /// @param uid The Unique Identifier of the AAC receiving tokens.
    /// @param tokens The number of colored tokens to deposit (in pWei).
    //-------------------------------------------------------------------------
    function depositFrom (
        address from,
        uint colorIndex,
        uint uid,
        uint tokens
    ) external {
        // tokens to deposit must be greater than 0
        require (tokens > 0);
        // colorIndex must be valid color
        require (colorIndex < coloredTokens.length);
        // token owner must have sufficient colored token balance
        require (tokens <= coloredTokens[colorIndex].balances[msg.sender]);
        // uid must be a valid UID
        require (uid < MAX_UID);
        // token owner must be owner of AAC #uid
        require (from == aac.ownerOf(uid));
        // msg.sender must be the approved address of AAC #uid, or an authorized
        //  operator for from
        require (
            msg.sender == aac.getApproved(uid) ||
            aac.isApprovedForAll(from, msg.sender)
        );
        // deduct tokens from token owner's account
        coloredTokens[colorIndex].balances[from] -= tokens;
        // add tokens to AAC #UID
        coloredTokens[colorIndex].balances[address(uid)] += tokens;
    }

    //-------------------------------------------------------------------------
    /// @notice Withdraw `(tokens/1000000000000000000).fixed(0,18)` colored 
    ///  tokens with index `colorIndex` from AAC #`uid` to sender's account.
    /// @dev Throws if amount to withdraw is zero. Throws if colorIndex is
    ///  greater than number of colored tokens. Throws if `uid` is greater
    ///  than maximum UID value. Throws if AAC #`uid` has insufficient balance
    ///  to withdraw. Throws if `from` is not the owner of AAC #`uid`.
    /// @param colorIndex The index of the color to withdraw.
    /// @param uid The Unique ID of the AAC whose tokens are being withdrawn.
    /// @param tokens The number of colored tokens to withdraw (in pWei).
    //-------------------------------------------------------------------------
    function withdraw (uint colorIndex, uint uid, uint tokens) external {
        // tokens to deposit must be greater than 0
        require (tokens > 0);
        // colorIndex must be valid color
        require (colorIndex < coloredTokens.length);
        // uid must be a valid UID
        require (uid < MAX_UID);
        // AAC #uid must have sufficient colored token balance
        require (tokens <= coloredTokens[colorIndex].balances[address(uid)]);
        // sender must be owner of AAC #uid
        require (msg.sender == aac.ownerOf(uid));
        // deduct tokens from AAC #UID
        coloredTokens[colorIndex].balances[address(uid)] -= tokens;
        // add tokens to sender's account
        coloredTokens[colorIndex].balances[msg.sender] += tokens;
    }

    //-------------------------------------------------------------------------
    /// @notice Withdraw `(tokens/1000000000000000000).fixed(0,18)` colored 
    ///  tokens with index `colorIndex` from AAC #`from` to `to`.
    /// @dev Throws if amount to withdraw is zero. Throws if colorIndex is
    ///  greater than number of colored tokens. Throws if `from` is greater
    ///  than maximum UID value. Throws if AAC #`from` has insufficient balance
    ///  to withdraw. Throws if `to` is not the owner of AAC #`from`. Throws
    ///  if sender is not the approved address of AAC #`from` or an authorized
    ///  operator for `to`.
    /// @param from The Unique ID of the AAC whose tokens are being withdrawn.
    /// @param to The recipient of withdrawn colored tokens.
    /// @param colorIndex The index of the color to withdraw.
    /// @param tokens The number of colored tokens to withdraw (in pWei).
    //-------------------------------------------------------------------------
    function withdrawFrom (
        uint from,
        address to,
        uint colorIndex,
        uint tokens
    ) external {        
        // tokens to deposit must be greater than 0
        require (tokens > 0);
        // colorIndex must be valid color
        require (colorIndex < coloredTokens.length);
        // uid must be a valid UID
        require (from < MAX_UID);
        // AAC #uid must have sufficient colored token balance
        require (tokens <= coloredTokens[colorIndex].balances[address(from)]);
        // sender must be owner of AAC #uid
        require (msg.sender == aac.ownerOf(from));
        // msg.sender must be the approved address of AAC #uid, or an authorized
        //  operator for from
        require (
            msg.sender == aac.getApproved(from) ||
            aac.isApprovedForAll(to, msg.sender)
        );
        // deduct tokens from AAC #UID
        coloredTokens[colorIndex].balances[address(from)] -= tokens;
        // add tokens to sender's account
        coloredTokens[colorIndex].balances[to] += tokens;
    }

    //-------------------------------------------------------------------------
    /// @notice Withdraw all uncolored PLAY tokens from AAC #`uid`.
    /// @dev Throws if amount to withdraw is zero. Throws if `uid` is greater
    ///  than maximum UID value. Emits transfer event.
    /// @param uid The Unique ID of the AAC whose tokens are being withdrawn.
    //-------------------------------------------------------------------------
    function withdrawTrappedPLAY(uint uid) external  {
        // uid must be a valid UID
        require(uid < MAX_UID);
        // create local address variable using uid
        address uidAddress = address(uid);
        // amount to withdraw must be more than zero
        uint trappedPLAY = playBalances[uidAddress];
        require (trappedPLAY > 0);
        // store owner address in local variable
        address owner = aac.ownerOf(uid);
        // deduct all PLAY balance from uid's wallet
        playBalances[uidAddress] -= trappedPLAY;
        // add PLAY to uid owner's wallet
        playBalances[owner] += trappedPLAY;
        // emit transfer event
        emit Transfer(uidAddress, owner, trappedPLAY);
    }
}