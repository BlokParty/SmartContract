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

//-------------------------------------------------------------------------------------------------
// PLAYToken contract - defines standard ERC-20 functionality.
//-------------------------------------------------------------------------------------------------
contract PLAYToken {
    //---------------------------------------------------------------------------------------------
    /// @dev Transfer emits when ownership of PLAY changes by any mechanism.
    ///  This event emits when tokens are destroyed ('to' == 0).
    //---------------------------------------------------------------------------------------------
    event Transfer (address indexed from, address indexed to, uint tokens);

    //---------------------------------------------------------------------------------------------
    /// @dev This emits when an approved spender is changed or
    ///  reaffirmed, or if the allowance amount changes.
    ///  The zero address indicates there is no approved address.
    //---------------------------------------------------------------------------------------------
    event Approval (address indexed tokenOwner, address indexed spender, uint tokens);
    
    // total number of tokens issued. Burning tokens reduces this amount
    uint totalPLAY = 1000000000;    // one billion
    // the token balances of all token holders
    mapping (address => uint) playBalances;
    // approved spenders and allowances of all token holders
    mapping (address => mapping (address => uint)) allowances;

    //---------------------------------------------------------------------------------------------
    // Transfer some amount of tokens from sender's account to another account.
    //---------------------------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        // sender's account must have sufficient balance to transfer
        require (playBalances[msg.sender] >= tokens);
        // For safety, tokens cannot be transferred to the 0 address unless burn is explicitly called
        require (to != 0);

        // subtract amount from sender
        playBalances[msg.sender] -= tokens;
        // add amount to token receiver
        playBalances[to] += tokens;
        // emit transfer event
        emit Transfer(msg.sender, to, tokens);
        
        return true;
    }

    //---------------------------------------------------------------------------------------------
    // Transfer some pre-approved amount of tokens from token owner's account to another account.
    //---------------------------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        // sender's allowance must be enough to transfer amount
        require (allowances[from][msg.sender] >= tokens);
        // token owner must have sufficient balance to transfer
        require (playBalances[from] >= tokens);
        // For safety, tokens cannot be transferred to the 0 address unless burn is explicitly called
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

    //---------------------------------------------------------------------------------------------
    // Allow another address to withdraw from your account, multiple times, up to the `tokens` amount.
    // Calling this function overwrites the previous spender and allowance.
    //---------------------------------------------------------------------------------------------
    function approve(address spender, uint tokens) external returns (bool success) {
        // set the spender's allowance to token amount
        allowances[msg.sender][spender] = tokens;
        // emit approval event
        emit Approval(msg.sender, spender, tokens);

        return true;
    }

    //---------------------------------------------------------------------------------------------
    // Query the number of tokens in circulation.
    //---------------------------------------------------------------------------------------------
    function totalSupply() external view returns (uint) { return totalPLAY; }

    //---------------------------------------------------------------------------------------------
    // Query the token holdings of an address
    //---------------------------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint) {
        require (tokenOwner != 0);
        return playBalances[tokenOwner];
    }

    //---------------------------------------------------------------------------------------------
    // Query the remaining allowance of an approved spender.
    //---------------------------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint) {
        return allowances[tokenOwner][spender];
    }

    //---------------------------------------------------------------------------------------------
    // Query the token name.
    //---------------------------------------------------------------------------------------------
    function name() external pure returns (string) { return "Persistent Licensing Algorithm for Yogapants"; }

    //---------------------------------------------------------------------------------------------
    // Query the token symbol.
    //---------------------------------------------------------------------------------------------
    function symbol() external pure returns (string) { return "PLAY"; }

    //---------------------------------------------------------------------------------------------
    // Query the number of allowed decimal places.
    //---------------------------------------------------------------------------------------------
    function decimals() external pure returns (uint8) { return 18; }
}


//-------------------------------------------------------------------------------------------------
// BurnToken contract - defines token burning functionality.
//-------------------------------------------------------------------------------------------------
contract BurnToken is PLAYToken {
    //---------------------------------------------------------------------------------------------
    // Sends an amount of tokens to the zero address. These tokens cannot be seen or recovered.
    //---------------------------------------------------------------------------------------------
    function burn(uint tokens) external returns (bool success) {
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

    //---------------------------------------------------------------------------------------------
    // Sends a pre-approved amount of tokens to the zero address.
    //---------------------------------------------------------------------------------------------
    function burnFrom(address from, uint tokens) external returns (bool success) {
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

//-------------------------------------------------------------------------------------------------
// LockToken contract - defines token locking and unlocking functionality.
//-------------------------------------------------------------------------------------------------
contract LockToken is BurnToken {
    /// @dev Lock emits when PLAY tokens become locked for any number of years by any mechanism.
    event Lock (address indexed tokenOwner, uint tokens);

    /// @dev Unlock emits when PLAY tokens become unlocked by any mechanism.
    event Unlock (address indexed tokenOwner, uint tokens);

    // Unix Timestamp for 1-1-2018 at 00:00:00. Used to calculate years since release.
    uint constant firstYearTimestamp = 1514764800;
    // Public variable. Starts at 0 and increments once every 365 days.
    uint public yearsSinceRelease;
    // Maximum number of years into the future locked tokens can be recovered.
    uint public maximumLockYears = 10;
    // Locked token balances by unlock year (maximum of yearsSinceRelease + maximumLockYears)  
    mapping (address => mapping(uint => uint)) lockedUntilYearTokens;

    //---------------------------------------------------------------------------------------------
    // Locks an amount of tokens for a number of years.
    //---------------------------------------------------------------------------------------------
    function lock(uint numberOfYears, uint tokens) external {
        // number of years must be a valid amount.
        require (numberOfYears > 0 && numberOfYears <= maximumLockYears);
        // sender's account must have sufficient balance to lock
        require (playBalances[msg.sender] >= tokens);

        // subtract amount from sender
        playBalances[msg.sender] -= tokens;
        // add amount to sender's locked token balance
        lockedUntilYearTokens[msg.sender][yearsSinceRelease + numberOfYears] += tokens;
        // emit lock event
        emit Lock(msg.sender, tokens);
    }

    //---------------------------------------------------------------------------------------------
    // Locks a pre-approved amount of tokens for a number of years.
    //---------------------------------------------------------------------------------------------
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
        lockedUntilYearTokens[from][yearsSinceRelease + numberOfYears] += tokens;
        // emit lock event
        emit Lock(from, tokens);
    }

    //---------------------------------------------------------------------------------------------
    // Transfers, then automatically locks an amount of tokens for a number of years.
    //---------------------------------------------------------------------------------------------
    function transferAndLock(address to, uint numberOfYears, uint tokens) external {
        // Initiates transfer. Transfer will fail if sender's balance is too low or "to" is zero
        transfer(to, tokens);

        // subtract amount from sender's balance
        playBalances[to] -= tokens;
        // add amount to token receiver's locked token balance
        lockedUntilYearTokens[to][yearsSinceRelease + numberOfYears] += tokens;
        // emit lock event
        emit Lock(msg.sender, tokens);
    }

    //---------------------------------------------------------------------------------------------
    // Transfers, then locks a pre-approved amount of tokens for a number of years.
    //---------------------------------------------------------------------------------------------
    function transferFromAndLock(address from, address to, uint numberOfYears, uint tokens) external {
        // Initiates transfer. Transfer will fail if sender's allowance is too low or 
        // token owner's balance is too low or "to" is zero
        transferFrom(from, to, tokens);

        // subtract amount from token owner's balance
        playBalances[to] -= tokens;
        // add amount to token receiver's locked token balance
        lockedUntilYearTokens[to][yearsSinceRelease + numberOfYears] += tokens;
        // emit lock event
        emit Lock(msg.sender, tokens);
    }

    //---------------------------------------------------------------------------------------------
    // Unlocks all qualifying tokens for a token owner. 
    //---------------------------------------------------------------------------------------------
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
        // check each year starting from 1 year after release for qualifying tokens to unlock
        for (uint i = 1; i <= yearsSinceRelease; ++i) {
            if(lockedUntilYearTokens[addressToUnlock][i] > 0) {
                // add qualifying tokens to tokens to unlock variable
                tokensToUnlock += lockedUntilYearTokens[addressToUnlock][i];
                // set locked token balance of year i to 0 
                lockedUntilYearTokens[addressToUnlock][i] = 0;
            }
        }
        // add qualifying tokens back to token owner's account balance
        playBalances[addressToUnlock] += tokensToUnlock;
        // emit unlock event
        emit Unlock (addressToUnlock, tokensToUnlock);
    }

    //---------------------------------------------------------------------------------------------
    // Unlocks all tokens of a valid year for a token owner. 
    //---------------------------------------------------------------------------------------------
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
        // retrieval year of locked tokens must be less than or equal to current year
        require (yearsSinceRelease >= year);
        // create local variable for unlock amount
        uint tokensToUnlock = lockedUntilYearTokens[addressToUnlock][year];
        // set locked token balance of year to 0
        lockedUntilYearTokens[addressToUnlock][year] = 0;
        // add qualifying tokens back to token owner's account balance
        playBalances[addressToUnlock] += tokensToUnlock;
        // emit unlock event
        emit Unlock(addressToUnlock, tokensToUnlock);
    }

    //---------------------------------------------------------------------------------------------
    // Query the total locked token holdings of an address
    //---------------------------------------------------------------------------------------------
    function getTotalLockedTokens (address tokenOwner) public view returns (uint lockedTokens) {
        for (uint i = 1; i < yearsSinceRelease + maximumLockYears; ++i) {
            lockedTokens += lockedUntilYearTokens[tokenOwner][i];
        }
    }

    //---------------------------------------------------------------------------------------------
    // Query the locked token holdings of an address
    //---------------------------------------------------------------------------------------------
    function getLockedTokensByYear (address tokenOwner, uint year) external view returns (uint) {
        return lockedUntilYearTokens[tokenOwner][year];
    }

    //---------------------------------------------------------------------------------------------
    // Updates the current year since release. Only works if more than 365 days of time has passed
    //---------------------------------------------------------------------------------------------
    function updateYearsSinceRelease() external {
        require (yearsSinceRelease < (block.timestamp - firstYearTimestamp) / (365 * 1 days));
        ++yearsSinceRelease;
    }
}


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


contract ColorToken is LockToken, Ownable {    
    // Color functions
    struct ColoredToken {
        address creator;
        string name;
        mapping (address => uint) balances;
    }
    
    ColoredToken[] coloredTokens;
    uint requiredHoldingForColorRegistration;

    function getColoredTokenBalance(address tokenOwner, uint colorIndex) external view returns (uint) {
        return coloredTokens[colorIndex].balances[tokenOwner];
    }

    function color(uint colorIndex, uint tokens) external {
        require (playBalances[msg.sender] >= tokens);
        coloredTokens[colorIndex].balances[msg.sender] += tokens;
        playBalances[msg.sender] -= tokens;
    }

    function colorFrom(address from, uint colorIndex, uint tokens) external {
        require (allowances[from][msg.sender] >= tokens);
        require (playBalances[from] >= tokens);
        
        allowances[from][msg.sender] -= tokens;
        coloredTokens[colorIndex].balances[from] += tokens;
        playBalances[msg.sender] -= tokens;
    }

    function uncolor(uint colorIndex, uint tokens) external {
        require (msg.sender == coloredTokens[colorIndex].creator);
        require (tokens <= coloredTokens[colorIndex].balances[msg.sender]);
        playBalances[msg.sender] += tokens;
        coloredTokens[colorIndex].balances[msg.sender] -= tokens;
    }

    function registerNewColor(string colorName) external {
        require (getTotalLockedTokens(msg.sender) >= requiredHoldingForColorRegistration);
        require (bytes(colorName).length > 0 && bytes(colorName).length < 32);
        coloredTokens.push(ColoredToken(msg.sender, colorName));
    }

    function setRequiredHoldingForColorRegistration(uint newAmount) external onlyOwner {
        require (newAmount > 0);
        requiredHoldingForColorRegistration = newAmount;
    }

    function spend(uint colorIndex, uint tokens) external {
        require (tokens <= coloredTokens[colorIndex].balances[msg.sender]);
        require (tokens > 0);
        // add the tokens back to the creator's colored token balance
        coloredTokens[colorIndex].balances[coloredTokens[colorIndex].creator] += tokens;
        // deduct the tokens from the sender's balance
        coloredTokens[colorIndex].balances[msg.sender] -= tokens;
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