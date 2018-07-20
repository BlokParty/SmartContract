pragma solidity ^0.4.24;

import "./PLAYToken.sol";

//-----------------------------------------------------------------------------
// BurnToken contract - defines token burning functionality.
//-----------------------------------------------------------------------------
contract BurnToken is PLAYToken {
    //-------------------------------------------------------------------------
    /// @notice Destroy `(tokens/1000000000000000000).fixed(0,18)` PLAY. These
    ///  tokens cannot be viewed or recovered.
    /// @dev Throws if amount to burn is zero. Throws if sender has
    ///  insufficient balance to burn. Emits transfer event.
    /// @param tokens The number of tokens to burn (in pWei). 
    /// @return True upon successful burn. Will throw if unsuccessful.
    //-------------------------------------------------------------------------
    function burn(uint tokens) external returns (bool) {
        // tokens to burn must be greater than zero.
        require (tokens > 0);
        // sender's account must have sufficient balance to burn
        require (playBalances[msg.sender] >= tokens);
        // subtract amount from token owner
        playBalances[msg.sender] -= tokens;
        // subtract amount from total supply
        totalPLAY -= tokens;
        // emit transfer event
        emit Transfer(msg.sender, address(0), tokens);

        return true;
    }

    //-------------------------------------------------------------------------
    /// @notice Destroy `(tokens/1000000000000000000).fixed(0,18)` PLAY from 
    /// `from`. These tokens cannot be viewed or recovered.
    /// @dev Throws if amount to burn is zero. Throws if sender has
    ///  insufficient allowance to burn. Throws if `from` has insufficient
    ///  balance to burn. Emits transfer event.
    /// @param from The token owner whose PLAY is being burned. Sender must be
    ///  an approved spender.
    /// @param tokens The number of tokens to burn (in pWei).
    /// @return True upon successful burn. Will throw if unsuccessful.
    //-------------------------------------------------------------------------
    function burnFrom(address from, uint tokens) external returns (bool) {
        // tokens to burn must be greater than zero.
        require (tokens > 0);
        // sender's allowance must be enough to burn amount
        require (allowances[from][msg.sender] >= tokens);
        // token owner's account must have sufficient balance to burn
        require (playBalances[from] >= tokens);
        // subtract amount from sender's allowance
        allowances[from][msg.sender] -= tokens;
        // subtract amount from token owner
        playBalances[from] -= tokens;
        // subtract amount from total supply
        totalPLAY -= tokens;
        // emit transfer event
        emit Transfer(from, address(0), tokens);

        return true;
    }
}