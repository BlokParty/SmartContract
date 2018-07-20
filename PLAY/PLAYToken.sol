pragma solidity ^0.4.24;

//-----------------------------------------------------------------------------
// PLAYToken contract - defines standard ERC-20 functionality.
//-----------------------------------------------------------------------------
contract PLAYToken {
    //-------------------------------------------------------------------------
    /// @dev Emits when ownership of PLAY changes by any mechanism. Also emits
    ///  when tokens are destroyed ('to' == 0).
    //-------------------------------------------------------------------------
    event Transfer (address indexed from, address indexed to, uint tokens);

    //-------------------------------------------------------------------------
    /// @dev Emits when an approved spender is changed or reaffirmed, or if
    ///  the allowance amount changes. The zero address indicates there is no
    ///  approved address.
    //-------------------------------------------------------------------------
    event Approval (
        address indexed tokenOwner, 
        address indexed spender, 
        uint tokens
    );
    
    // total number of tokens in circulation (in pWei). Burning tokens reduces this amount
    uint totalPLAY = 1000000000 * 10**18;    // one billion
    // the token balances of all token holders
    mapping (address => uint) playBalances;
    // approved spenders and allowances of all token holders
    mapping (address => mapping (address => uint)) allowances;

    //-------------------------------------------------------------------------
    /// @notice Send `(tokens/1000000000000000000).fixed(0,18)` PLAY to `to`.
    /// @dev Throws if amount to send is zero. Throws if `msg.sender` has
    ///  insufficient balance for transfer. Throws if `to` is the zero address.
    /// @param to The address to where PLAY is being sent.
    /// @param tokens The number of tokens to send (in pWei).
    /// @return True upon successful transfer. Will throw if unsuccessful.
    //-------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool) {
        // must be sending more than zero tokens
        require (tokens > 0);
        // sender's account must have sufficient balance to transfer
        require (playBalances[msg.sender] >= tokens);
        // Tokens cannot be transferred to 0 unless burn is explicitly called
        require (to != 0);

        // subtract amount from sender
        playBalances[msg.sender] -= tokens;
        // add amount to token receiver
        playBalances[to] += tokens;
        // emit transfer event
        emit Transfer(msg.sender, to, tokens);
        
        return true;
    }

    //-------------------------------------------------------------------------
    /// @notice Send `(tokens/1000000000000000000).fixed(0,18)` PLAY from
    ///  `from` to `to`.
    /// @dev Throws if amount to send is zero. Throws if `msg.sender` has
    ///  insufficient allowance for transfer. Throws if `from` has
    ///  insufficient balance for transfer. Throws if `to` is the zero address.
    /// @param from The address from where PLAY is being sent. Sender must be
    ///  an approved spender.
    /// @param to The token owner whose PLAY is being sent.
    /// @param tokens The number of tokens to send (in pWei).
    /// @return True upon successful transfer. Will throw if unsuccessful.
    //-------------------------------------------------------------------------
    function transferFrom(
        address from, 
        address to, 
        uint tokens
    ) public returns (bool) {
        // sender's allowance must be enough to transfer amount
        require (allowances[from][msg.sender] >= tokens);
        // token owner must have sufficient balance to transfer
        require (playBalances[from] >= tokens);
        // Tokens cannot be transferred to 0 unless burnFrom is explicitly
        //  called
        require (to != 0);

        // subtract amount from sender's allowance
        allowances[from][msg.sender] -= tokens;
        // subtract amount from token owner
        playBalances[from] -= tokens;
        // add amount to token receiver
        playBalances[to] += tokens;
        // emit transfer event
        emit Transfer(from, to, tokens);

        return true;
    }

    //-------------------------------------------------------------------------
    /// @notice Allow `spender` to withdraw from your account, multiple times,
    ///  up to `(tokens/1000000000000000000).fixed(0,18)` PLAY. Calling this
    ///  function overwrites the previous allowance of spender.
    /// @dev Emits approval event
    /// @param spender The address to authorize as a spender
    /// @param tokens The new token allowance of spender (in pWei).
    //-------------------------------------------------------------------------
    function approve(address spender, uint tokens) external returns (bool) {
        // set the spender's allowance to token amount
        allowances[msg.sender][spender] = tokens;
        // emit approval event
        emit Approval(msg.sender, spender, tokens);

        return true;
    }

    //-------------------------------------------------------------------------
    /// @notice Get the total number of tokens in circulation.
    /// @return Total tokens tracked by this contract.
    //-------------------------------------------------------------------------
    function totalSupply() external view returns (uint) { return totalPLAY; }

    //-------------------------------------------------------------------------
    /// @notice Get the number of PLAY tokens owned by `tokenOwner`.
    /// @dev Throws if trying to query the zero address.
    /// @param tokenOwner The PLAY token owner.
    /// @return The number of PLAY tokens owned by `tokenOwner` (in pWei).
    //-------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint) {
        require (tokenOwner != 0);
        return playBalances[tokenOwner];
    }

    //-------------------------------------------------------------------------
    /// @notice Get the remaining allowance of `spender` for `tokenOwner`.
    /// @param tokenOwner The PLAY token owner.
    /// @param spender The approved spender address.
    /// @return The remaining allowance of `spender` for `tokenOwner`.
    //-------------------------------------------------------------------------
    function allowance(
        address tokenOwner, 
        address spender
    ) public view returns (uint) {
        return allowances[tokenOwner][spender];
    }

    //-------------------------------------------------------------------------
    /// @notice Get the token's name.
    /// @return The token's name as a string
    //-------------------------------------------------------------------------
    function name() external pure returns (string) { 
        return "Pretty Leggings And Yogapants Network"; 
    }

    //-------------------------------------------------------------------------
    /// @notice Get the token's ticker symbol.
    /// @return The token's ticker symbol as a string
    //-------------------------------------------------------------------------
    function symbol() external pure returns (string) { return "PLAY"; }

    //-------------------------------------------------------------------------
    /// @notice Get the number of allowed decimal places for the token.
    /// @return The number of allowed decimal places for the token.
    //-------------------------------------------------------------------------
    function decimals() external pure returns (uint8) { return 18; }
}