pragma solidity ^0.4.24;

import "./LockToken.sol";
import "./Ownable.sol";

//-----------------------------------------------------------------------------
// Color Token Contract - Changes ownership to a new address
//-----------------------------------------------------------------------------
contract ColorToken is LockToken, Ownable {
    //-------------------------------------------------------------------------
    /// @dev Emits when a new colored token is created.
    //-------------------------------------------------------------------------
    event NewColor(address indexed creator, string name);
    //-------------------------------------------------------------------------
    /// @dev Emits when PLAY tokens are redeemed for colored tokens.
    //-------------------------------------------------------------------------
    event RedeemColor(
        address indexed tokenOwner, 
        uint indexed color, 
        uint amount
    );
    //-------------------------------------------------------------------------
    /// @dev Emits when colored tokens are spent by any mechanism.
    //-------------------------------------------------------------------------
    event SpendColor(
        address indexed tokenOwner, 
        uint indexed color, 
        uint amount
    );

    // Colored token data
    struct ColoredToken {
        address creator;
        string name;
        mapping (address => uint) balances;
    }
    // array containing all colored token data
    ColoredToken[] coloredTokens;
    // required locked tokens needed to register a color (in pWei)
    uint requiredLockedForColorReg = 10000;

    //-------------------------------------------------------------------------
    /// @notice Set required total locked tokens to 
    ///  `(newAmount/1000000000000000000).fixed(0,18)`.
    /// @dev Throws if the sender is not the contract owner. Throws if new
    ///  amount is zero, or greater than total tokens.
    /// @param newAmount The new required locked token amount (in pWei).
    //-------------------------------------------------------------------------
    function setRequiredLockedForColorRegistration(
        uint newAmount
    ) external onlyOwner {
        // newAmount must be greater than 0 and less than total tokens
        require (newAmount > 0 && newAmount < totalPLAY);
        requiredLockedForColorReg = newAmount;
    }
    
    //-------------------------------------------------------------------------
    /// @notice Registers `colorName` as a new colored token. Must own
    ///  `requiredLockedForColorReg` locked tokens as a requirement.
    /// @dev Throws if `msg.sender` has insufficient locked tokens. Throws if
    ///  colorName is empty or is longer than 32 characters.
    /// @param colorName The name for the new colored token.
    /// @return Index number for the new colored token.
    //-------------------------------------------------------------------------
    function registerNewColor(string colorName) external returns (uint) {
        // sender must have enough locked tokens
        require (
            getTotalLockedTokens(msg.sender) >= requiredLockedForColorReg
        );
        // colorName must be a valid length
        require (bytes(colorName).length > 0 && bytes(colorName).length < 32);
        // push new colored token to colored token array and store the index
        uint index = coloredTokens.push(ColoredToken(msg.sender, colorName));
        return index;
    }

    //-------------------------------------------------------------------------
    /// @notice Send `(tokens/1000000000000000000).fixed(0,18)` PLAY to color 
    ///  creator, then redeem that many colored tokens.
    /// @dev Throws if tokens to color is zero. Throws if colorIndex is 
    ///  greater than number of colored tokens. Throws if `msg.sender` has
    ///  insufficient balance for transfer. Emits transfer and color events.
    /// @param colorIndex The index of the color to redeem.
    /// @param tokens The number of tokens to send (in pWei).
    //-------------------------------------------------------------------------
    function color(uint colorIndex, uint tokens) external {
        // colorIndex must be less than the number of colored tokens.
        require (colorIndex < coloredTokens.length);
        // Initiate transfer. Fails if sender's balance is too low.
        transfer(coloredTokens[colorIndex].creator, tokens);
        // add amount to sender's colored token balance
        coloredTokens[colorIndex].balances[msg.sender] += tokens;
        // emit redeem color event
        emit RedeemColor(msg.sender, colorIndex, tokens);
    }

    //-------------------------------------------------------------------------
    /// @notice Send `(tokens/1000000000000000000).fixed(0,18)` PLAY from 
    ///  `from` to color creator, then redeem that many colored tokens.
    /// @dev Throws if tokens to color is zero. Throws if colorIndex is
    ///  greater than number of colored tokens. Throws if `msg.sender` has
    ///  insufficient allowance for transfer. Throws if `from` has 
    ///  insufficient balance for transfer. Emits transfer and color events.
    /// @param from The address whose PLAY is being redeemed for colored 
    ///  tokens. Sender must be an approved spender.
    /// @param colorIndex The index of the color to redeem.
    /// @param tokens The number of tokens to send (in pWei).
    //-------------------------------------------------------------------------
    function colorFrom(address from, uint colorIndex, uint tokens) external {
        // colorIndex must be less than the number of colored tokens.
        require (colorIndex < coloredTokens.length);
        // Initiate transferFrom. Fails if sender's allowance is too low or
        //  token owner's balance is too low.
        transferFrom(from, coloredTokens[colorIndex].creator, tokens);
        // add amount to sender's colored token balance
        coloredTokens[colorIndex].balances[from] += tokens;
        // emit redeem color event
        emit RedeemColor(from, colorIndex, tokens);
    }

    //-------------------------------------------------------------------------
    /// @notice Spend `(tokens/1000000000000000000).fixed(0,18)` colored 
    ///  tokens with index `colorIndex`.
    /// @dev Throws if tokens to spend is zero. Throws if colorIndex is
    ///  greater than number of colored tokens. Throws if `msg.sender` has
    ///  insufficient balance to spend.
    /// @param colorIndex The index of the color to spend.
    /// @param tokens The number of colored tokens to spend (in pWei).
    /// @return True if spend successful. Throw if unsuccessful.
    //-------------------------------------------------------------------------
    function spend(uint colorIndex, uint tokens) external returns (bool) {
        // tokens to spend must be greater than zero.
        require (tokens > 0);
        // colorIndex must be valid color
        require (colorIndex < coloredTokens.length);
        // token owner's balance must be enough to spend tokens
        require (coloredTokens[colorIndex].balances[msg.sender] >= tokens);
        // deduct the tokens from the sender's balance
        coloredTokens[colorIndex].balances[msg.sender] -= tokens;
        // emit spend event
        emit SpendColor(msg.sender, colorIndex, tokens);
        return true;
    }

    //-------------------------------------------------------------------------
    /// @notice Spend `(tokens/1000000000000000000).fixed(0,18)` colored
    ///  tokens with color index `index` from `from`.
    /// @dev Throws if tokens to spend is zero. Throws if colorIndex is 
    ///  greater than number of colored tokens. Throws if `msg.sender` is not
    ///  the colored token's creator. Throws if `from` has insufficient
    ///  balance to spend.
    /// @param from The address whose colored tokens are being spent.
    /// @param colorIndex The index of the color to redeem. Sender must be
    ///  this colored token's creator.
    /// @param tokens The number of tokens to send (in pWei).
    //-------------------------------------------------------------------------
    function spendFrom(
        address from, 
        uint colorIndex, 
        uint tokens
    ) external returns (bool) {
        // tokens to spend must be greater than zero.
        require (tokens > 0);
        // colorIndex must be valid color
        require (colorIndex < coloredTokens.length);
        // sender must be colored token creator
        require (msg.sender == coloredTokens[colorIndex].creator);
        // token owner's balance must be enough to spend tokens
        require (coloredTokens[colorIndex].balances[from] >= tokens);
        // deduct the tokens from token owner's balance
        coloredTokens[colorIndex].balances[from] -= tokens;
        // emit spend event
        emit SpendColor(from, colorIndex, tokens);
        return true;
    }

    //-------------------------------------------------------------------------
    /// @notice Get the number of colored tokens with color index `colorIndex`
    ///  owned by `tokenOwner`.
    /// @param tokenOwner The colored token owner.
    /// @param colorIndex Index of the colored token to query.
    /// @return The number of colored tokens with color index `colorIndex`
    ///  owned by `tokenOwner`.
    //-------------------------------------------------------------------------
    function getColoredTokenBalance(
        address tokenOwner, 
        uint colorIndex
    ) external view returns (uint) {
        return coloredTokens[colorIndex].balances[tokenOwner];
    }
}