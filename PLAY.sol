pragma solidity ^0.4.24;

/*
interface PLAYInterface {
    // events
    event Transfer (address indexed from, address indexed to, uint tokens);
    event Approval (address indexed tokenOwner, address indexed spender, uint tokens);
    event Lock (address indexed tokenOwner, uint tokens);
    event Unlock (address indexed tokenOwner, uint tokens);

    // ERC-721 required functions
    function totalSupply () external view returns (uint);
    function balanceOf (address tokenOwner) external view returns (uint balance);
    function allowance (address tokenOwner, address spender) external view returns (uint remaining);
    function transfer (address to, uint tokens) public returns (bool success);
    function approve (address spender, uint tokens) external returns (bool success);
    function transferFrom (address from, address to, uint tokens) public returns (bool success);
    
    // ERC-721 optional functions
    function name () external pure returns (string);
    function symbol () external pure returns (string);
    function decimals () external pure returns (uint8);

    // burn token functions
    function burn (uint tokens) external returns (bool success);
    function burnFrom (address from, uint tokens) external returns (bool success);

    // lock token functions
    function getTotalLockedTokens (address from) public view returns (uint lockedTokens);
    function getLockedTokensByYear (address from, uint year) external view returns (uint);
    function lock (uint numberOfYears, uint tokens) external;
    function lockFrom (address from, uint numberOfYears, uint tokens) external; 
    function transferAndLock (address to, uint numberOfYears, uint tokens) external;
    function transferFromAndLock(address from, address to, uint numberOfYears, uint tokens) external; 
    function unlockAll (address unlockAddress) external;
    function unlockByYear (address from, uint year) external;
    function updateYearsSinceRelease () external;
    
    // color token functions
    function getColoredTokenBalance (address tokenOwner, uint tokenColor) external view returns (uint);
    function color (uint tokenColor, uint tokens) external;
    function uncolor (uint tokenColor, uint tokens) external;
    function spend (uint colorIndex, uint tokens) external;
    function deposit (uint colorIndex, uint uid, uint tokens) external;
    function withdraw (uint colorIndex, uint uid, uint tokens) external;
}
*/


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
    
    // total number of tokens issued. Burning tokens reduces this amount
    uint totalPLAY = 1000000000;    // one billion
    // the token balances of all token holders
    mapping (address => uint) playBalances;
    // approved spenders and allowances of all token holders
    mapping (address => mapping (address => uint)) allowances;

    //-------------------------------------------------------------------------
    /// @notice Send `(tokens/1000000000000000000).fixed(0,18)` PLAY to `to`.
    /// @dev Throws if `msg.sender` has insufficient balance for transfer.
    ///  Throws if `to` is the zero address.
    /// @param to The address to where PLAY is being sent.
    /// @param tokens The number of tokens to send (in pWei).
    /// @return True upon successful transfer. Will throw if unsuccessful.
    //-------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool) {
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
    /// @dev Throws if `msg.sender` has insufficient allowance for transfer.
    ///  Throws if `from` has insufficient balance for transfer. Throws if
    ///  `to` is the zero address.
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
    /// @notice Get the number of tokens owned by `tokenOwner`.
    /// @return The number of tokens owned by `tokenOwner` (in pWei).
    //-------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint) {
        require (tokenOwner != 0);
        return playBalances[tokenOwner];
    }

    //-------------------------------------------------------------------------
    /// @notice Get the remaining allowance of `spender` for `tokenOwner`.
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


//-----------------------------------------------------------------------------
// BurnToken contract - defines token burning functionality.
//-----------------------------------------------------------------------------
contract BurnToken is PLAYToken {
    //-------------------------------------------------------------------------
    /// @notice Destroy `(tokens/1000000000000000000).fixed(0,18)` PLAY. These
    ///  tokens cannot be viewed or recovered.
    /// @dev Throws if `from` has insufficient balance to burn. Emits transfer
    ///  event.
    /// @param tokens The number of tokens to burn (in pWei). 
    /// @return True upon successful burn. Will throw if unsuccessful.
    //-------------------------------------------------------------------------
    function burn(uint tokens) external returns (bool) {
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
    /// @dev Throws if `msg.sender` has insufficient allowance to burn. Throws
    ///  if `from` has insufficient balance to burn. Emits transfer event.
    /// @param from The token owner whose PLAY is being burned. Sender must be
    ///  an approved spender.
    /// @param tokens The number of tokens to burn (in pWei).
    /// @return True upon successful burn. Will throw if unsuccessful.
    //-------------------------------------------------------------------------
    function burnFrom(address from, uint tokens) external returns (bool) {
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


//-----------------------------------------------------------------------------
// LockToken contract - defines token locking and unlocking functionality.
//-----------------------------------------------------------------------------
contract LockToken is BurnToken {
    //-------------------------------------------------------------------------
    /// @dev Emits when PLAY tokens become locked for any number of years by
    ///  any mechanism.
    //-------------------------------------------------------------------------
    event Lock (address indexed tokenOwner, uint tokens);

    //-------------------------------------------------------------------------
    /// @dev Emits when PLAY tokens become unlocked by any mechanism.
    //-------------------------------------------------------------------------
    event Unlock (address indexed tokenOwner, uint tokens);

    // Unix Timestamp for 1-1-2018 at 00:00:00.
    //  Used to calculate years since release.
    uint constant firstYearTimestamp = 1514764800;
    // Tracks years since release. Starts at 0 and increments every 365 days.
    uint public currentYear;
    // Maximum number of years into the future locked tokens can be recovered.
    uint public maximumLockYears = 10;
    // Locked token balances by unlock year  
    mapping (address => mapping(uint => uint)) tokensLockedUntilYear;

    //-------------------------------------------------------------------------
    /// @notice Lock `(tokens/1000000000000000000).fixed(0,18)` PLAY for
    ///  `numberOfYears` years.
    /// @dev Throws if numberOfYears is zero or greater than maximumLockYears.
    ///  Throws if `msg.sender` has insufficient balance to lock.
    /// @param numberOfYears The number of years the tokens will be locked.
    /// @param tokens The number of tokens to lock (in pWei).
    //-------------------------------------------------------------------------
    function lock(uint numberOfYears, uint tokens) external {
        // number of years must be a valid amount.
        require (numberOfYears > 0 && numberOfYears <= maximumLockYears);
        // sender's account must have sufficient balance to lock
        require (playBalances[msg.sender] >= tokens);

        // subtract amount from sender
        playBalances[msg.sender] -= tokens;
        // add amount to sender's locked token balance
        tokensLockedUntilYear[msg.sender][currentYear+numberOfYears] += tokens;
        // emit lock event
        emit Lock(msg.sender, tokens);
    }

    //-------------------------------------------------------------------------
    /// @notice Lock `(tokens/1000000000000000000).fixed(0,18)` PLAY from 
    ///  `from` for `numberOfYears` years.
    /// @dev Throws if numberOfYears is zero or greater than maximumLockYears.
    ///  Throws if `msg.sender` has insufficient allowance to lock. Throws if
    ///  `from` has insufficient balance to lock.
    /// @param from The token owner whose PLAY is being locked. Sender must be
    ///  an approved spender.
    /// @param numberOfYears The number of years the tokens will be locked.
    /// @param tokens The number of tokens to lock (in pWei).
    //-------------------------------------------------------------------------
    function lockFrom(address from, uint numberOfYears, uint tokens) external {
        // number of years must be a valid amount.
        require (numberOfYears > 0 && numberOfYears <= maximumLockYears);
        // sender's allowance must be enough to lock amount
        require (allowances[from][msg.sender] >= tokens);
        // token owner's account must have sufficient balance to lock
        require (playBalances[from] >= tokens);

        // subtract amount from sender's allowance
        allowances[from][msg.sender] -= tokens;
        // subtract amount from token owner's balance
        playBalances[from] -= tokens;
        // add amount to token owner's locked token balance
        tokensLockedUntilYear[from][currentYear + numberOfYears] += tokens;
        // emit lock event
        emit Lock(from, tokens);
    }

    //-------------------------------------------------------------------------
    /// @notice Send `(tokens/1000000000000000000).fixed(0,18)` PLAY to `to`,
    ///  then lock for `numberOfYears` years.
    /// @dev Throws if `msg.sender` has insufficient balance for transfer.
    ///  Throws if `to` is the zero address. Emits transfer and lock events.
    /// @param to The address to where PLAY is being sent and locked.
    /// @param numberOfYears The number of years the tokens will be locked.
    /// @param tokens The number of tokens to send (in pWei).
    //-------------------------------------------------------------------------
    function transferAndLock(
        address to, 
        uint numberOfYears, 
        uint tokens
    ) external {
        // Transfer will fail if sender's balance is too low or "to" is zero
        transfer(to, tokens);

        // subtract amount from sender's balance
        playBalances[to] -= tokens;
        // add amount to token receiver's locked token balance
        tokensLockedUntilYear[to][currentYear + numberOfYears] += tokens;
        // emit lock event
        emit Lock(msg.sender, tokens);
    }

    //-------------------------------------------------------------------------
    /// @notice Send `(tokens/1000000000000000000).fixed(0,18)` PLAY from 
    ///  `from` to `to`, then lock for `numberOfYears` years.
    /// @dev Throws if `msg.sender` has insufficient allowance for transfer.
    ///  Throws if `from` has insufficient balance for transfer. Throws if
    ///  `to` is the zero address. Emits transfer and lock events.
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
    ) external {
        // Initiate transfer. Transfer will fail if sender's allowance is too
        //  low, token owner's balance is too low, or "to" is zero
        transferFrom(from, to, tokens);

        // subtract amount from token owner's balance
        playBalances[to] -= tokens;
        // add amount to token receiver's locked token balance
        tokensLockedUntilYear[to][currentYear + numberOfYears] += tokens;
        // emit lock event
        emit Lock(msg.sender, tokens);
    }

    //-------------------------------------------------------------------------
    /// @notice Unlock all qualifying tokens for `tokenOwner`. Sender must 
    ///  either be tokenOwner or an approved address.
    /// @dev If tokenOwner is empty, tokenOwner is set to msg.sender. Throws
    ///  if sender is not tokenOwner or an approved spender (allowance > 0).
    /// @param tokenOwner The token owner whose tokens will unlock.
    //-------------------------------------------------------------------------
    function unlockAll(address tokenOwner) external {
        // create local variable for token owner
        address addressToUnlock = tokenOwner;
        // if tokenOwner parameter is empty, set tokenOwner to sender
        if (addressToUnlock == address(0)) {
            addressToUnlock = msg.sender;
        }
        // sender must either be tokenOwner or an approved address
        if (msg.sender != addressToUnlock) {
            require (allowances[addressToUnlock][msg.sender] > 0);
        }

        // create local variable for unlock total
        uint tokensToUnlock;
        // check each year starting from 1 year after release
        for (uint i = 1; i <= currentYear; ++i) {
            // check for qualifying tokens to unlock
            if(tokensLockedUntilYear[addressToUnlock][i] > 0) {
                // add qualifying tokens to tokens to unlock variable
                tokensToUnlock += tokensLockedUntilYear[addressToUnlock][i];
                // set locked token balance of year i to 0 
                tokensLockedUntilYear[addressToUnlock][i] = 0;
            }
        }
        // add qualifying tokens back to token owner's account balance
        playBalances[addressToUnlock] += tokensToUnlock;
        // emit unlock event
        emit Unlock (addressToUnlock, tokensToUnlock);
    }

    //-------------------------------------------------------------------------
    /// @notice Unlock all tokens locked until `year` years since 2018 for 
    ///  `tokenOwner`. Sender must be tokenOwner or an approved address.
    /// @dev If tokenOwner is empty, tokenOwner is set to msg.sender. Throws
    ///  if sender is not tokenOwner or an approved spender (allowance > 0).
    /// @param tokenOwner The token owner whose tokens will unlock.
    /// @param year Number of years since 2018 the tokens were locked until.
    //-------------------------------------------------------------------------
    function unlockByYear(address tokenOwner, uint year) external {
        // create local variable for token owner
        address addressToUnlock = tokenOwner;
        // if tokenOwner parameter is empty, set tokenOwner to sender
        if (addressToUnlock == address(0)) {
            addressToUnlock = msg.sender;
        }
        // sender must either be tokenOwner or an approved address
        if (msg.sender != addressToUnlock) {
            require (allowances[addressToUnlock][msg.sender] > 0);
        }
        // year of locked tokens must be less than or equal to current year
        require (currentYear >= year);
        // create local variable for unlock amount
        uint tokensToUnlock = tokensLockedUntilYear[addressToUnlock][year];
        // set locked token balance of year to 0
        tokensLockedUntilYear[addressToUnlock][year] = 0;
        // add qualifying tokens back to token owner's account balance
        playBalances[addressToUnlock] += tokensToUnlock;
        // emit unlock event
        emit Unlock(addressToUnlock, tokensToUnlock);
    }

    //-------------------------------------------------------------------------
    /// @notice Update the current year.
    /// @dev Throws if less than 365 days has passed since currentYear.
    //-------------------------------------------------------------------------
    function updateYearsSinceRelease() external {
        // check if years since first year is greater than the currentYear
        uint elapsed = (block.timestamp - firstYearTimestamp) / (365 * 1 days);
        require (currentYear < elapsed);
        // increment years since release
        ++currentYear;
    }

    //-------------------------------------------------------------------------
    /// @notice Get the total locked token holdings of `tokenOwner`.
    /// @return Total locked token holdings of an address.
    //-------------------------------------------------------------------------
    function getTotalLockedTokens(
        address tokenOwner
    ) public view returns (uint lockedTokens) {
        for (uint i = 1; i < currentYear + maximumLockYears; ++i) {
            lockedTokens += tokensLockedUntilYear[tokenOwner][i];
        }
    }

    //-------------------------------------------------------------------------
    /// @notice Get the locked token holdings of `tokenOwner` unlockable in
    ///  `(year + 2018)`.
    /// @return Locked token holdings of an address for `(year + 2018)`.
    //-------------------------------------------------------------------------
    function getLockedTokensByYear(
        address tokenOwner, 
        uint year
    ) external view returns (uint) {
        return tokensLockedUntilYear[tokenOwner][year];
    }
}


//-----------------------------------------------------------------------------
/// @title Ownable
/// @dev The Ownable contract has an owner address, and provides basic 
///  authorization control functions, this simplifies the implementation of
///  "user permissions".
//-----------------------------------------------------------------------------
contract Ownable {
    /// @dev Emits when owner address changes by any mechanism.
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
    uint requiredLockedForColorRegistration;

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
        requiredLockedForColorRegistration = newAmount;
    }
    
    //-------------------------------------------------------------------------
    /// @notice Send `(tokens/1000000000000000000).fixed(0,18)` PLAY to color
    ///  creator, then redeem that many colored tokens.
    /// @dev Throws if `msg.sender` has insufficient locked tokens. Throws if
    ///  colorName is empty or is longer than 32 characters.
    /// @param colorName The name for the new colored token.
    /// @return Index number for the new colored token.
    //-------------------------------------------------------------------------
    function registerNewColor(string colorName) external returns (uint) {
        // sender must have enough locked tokens
        require (
            getTotalLockedTokens(msg.sender) >= requiredLockedForColorRegistration
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
    /// @dev Throws if `msg.sender` has insufficient balance for transfer.
    ///  Throws if `to` is the zero address. Throws if colorIndex is greater
    ///  than number of colored tokens. Emits transfer and color events.
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
    /// @dev Throws if `msg.sender` has insufficient allowance for transfer.
    ///  Throws if `from` has insufficient balance for transfer. Throws if
    ///  `to` is the zero address.
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
    /// @dev Throws if `msg.sender` has insufficient allowance for spend.
    ///  Throws if colorIndex is greater than number of colored tokens. Throws
    ///  if tokens to spend is zero.
    /// @param from The address whose PLAY is being spent.
    /// @param colorIndex The index of the color to spend.
    /// @param tokens The number of colored tokens to spend (in pWei).
    /// @return True if spend successful. Throw if unsuccessful.
    //-------------------------------------------------------------------------
    function spend(uint colorIndex, uint tokens) external returns (bool) {
        // colorIndex must be valid color
        require (colorIndex < coloredTokens.length);
        // token owner's balance must be enough to spend tokens
        require (coloredTokens[colorIndex].balances[msg.sender] >= tokens);
        // tokens to spend must be greater than zero.
        require (tokens > 0);
        // deduct the tokens from the sender's balance
        coloredTokens[colorIndex].balances[msg.sender] -= tokens;
        // emit spend event
        emit SpendColor(msg.sender, colorIndex, tokens);
        return true;
    }

    //-------------------------------------------------------------------------
    /// @notice Send `(tokens/1000000000000000000).fixed(0,18)` PLAY from 
    ///  `from` to color creator, then redeem that many colored tokens.
    /// @dev Throws if `msg.sender` has insufficient allowance for transfer.
    ///  Throws if `from` has insufficient balance for transfer. Throws if
    ///  `to` is the zero address.
    /// @param from The address whose PLAY is being redeemed for colored 
    ///  tokens. Sender must be an approved spender.
    /// @param colorIndex The index of the color to redeem.
    /// @param tokens The number of tokens to send (in pWei).
    //-------------------------------------------------------------------------
    function spendFrom(
        address from, 
        uint colorIndex, 
        uint tokens
    ) external returns (bool) {
        require (colorIndex < coloredTokens.length);
        require (msg.sender == coloredTokens[colorIndex].creator);
        require (coloredTokens[colorIndex].balances[from] >= tokens);
        require (tokens > 0);
        // deduct the tokens from token owner's balance
        coloredTokens[colorIndex].balances[from] -= tokens;
    }

    function getColoredTokenBalance(address tokenOwner, uint colorIndex) external view returns (uint) {
        return coloredTokens[colorIndex].balances[tokenOwner];
    }
}


contract AACOwnership {
    function ownerOf(uint256 _tokenId) public view returns (address);
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) public view returns (bool);
}


contract AACInteraction is ColorToken {
    AACOwnership aac;
    uint constant maxUid = 72057594037927936;

    function setAacContractAddress (address aacAddress) external onlyOwner {
        aac = AACOwnership(aacAddress);
    }

    function deposit (uint colorIndex, uint uid, uint tokens) external {
        require (tokens <= coloredTokens[colorIndex].balances[msg.sender]);
        require (uid < maxUid);
        require (tokens > 0);
        require (
            msg.sender == aac.ownerOf(uid) ||
            msg.sender == aac.getApproved(uid) ||
            aac.isApprovedForAll(aac.ownerOf(uid), msg.sender)
        );
        coloredTokens[colorIndex].balances[address(uid)] += tokens;
        coloredTokens[colorIndex].balances[msg.sender] -= tokens;
    }

    function withdraw (uint colorIndex, uint uid, uint tokens) external {
        require (tokens <= coloredTokens[colorIndex].balances[address(uid)]);
        require (uid < maxUid);
        require (tokens > 0);
        require (
            msg.sender == aac.ownerOf(uid) ||
            msg.sender == aac.getApproved(uid) ||
            aac.isApprovedForAll(aac.ownerOf(uid), msg.sender)
        );
        coloredTokens[colorIndex].balances[address(uid)] -= tokens;
        coloredTokens[colorIndex].balances[msg.sender] += tokens;
    }
}