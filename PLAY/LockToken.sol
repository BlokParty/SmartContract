pragma solidity ^0.4.24;

import "./BurnToken.sol";

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
    uint constant FIRST_YEAR_TIMESTAMP = 1514764800;
    // Tracks years since release. Starts at 0 and increments every 365 days.
    uint public currentYear;
    // Maximum number of years into the future locked tokens can be recovered.
    uint public maximumLockYears = 10;
    // Locked token balances by unlock year  
    mapping (address => mapping(uint => uint)) tokensLockedUntilYear;

    //-------------------------------------------------------------------------
    /// @notice Lock `(tokens/1000000000000000000).fixed(0,18)` PLAY for
    ///  `numberOfYears` years.
    /// @dev Throws if amount to lock is zero. Throws if numberOfYears is zero
    ///  or greater than maximumLockYears. Throws if `msg.sender` has 
    ///  insufficient balance to lock.
    /// @param numberOfYears The number of years the tokens will be locked.
    /// @param tokens The number of tokens to lock (in pWei).
    //-------------------------------------------------------------------------
    function lock(uint numberOfYears, uint tokens) external {
        // tokens to spend must be greater than zero.
        require (tokens > 0);
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
    /// @dev Throws if amount to lock is zero. Throws if numberOfYears is zero
    ///  or greater than maximumLockYears. Throws if `msg.sender` has
    ///  insufficient allowance to lock. Throws if `from` has insufficient
    ///  balance to lock.
    /// @param from The token owner whose PLAY is being locked. Sender must be
    ///  an approved spender.
    /// @param numberOfYears The number of years the tokens will be locked.
    /// @param tokens The number of tokens to lock (in pWei).
    //-------------------------------------------------------------------------
    function lockFrom(address from, uint numberOfYears, uint tokens) external {
        // tokens to spend must be greater than zero.
        require (tokens > 0);
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
            // add qualifying tokens to tokens to unlock variable
            tokensToUnlock += tokensLockedUntilYear[addressToUnlock][i];
            // set locked token balance of year i to 0 
            tokensLockedUntilYear[addressToUnlock][i] = 0;
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
        uint secondsSinceRelease = block.timestamp - FIRST_YEAR_TIMESTAMP;
        require (currentYear < secondsSinceRelease / (365 * 1 days));
        // increment years since release
        ++currentYear;
    }

    //-------------------------------------------------------------------------
    /// @notice Get the total locked token holdings of `tokenOwner`.
    /// @param tokenOwner The locked token owner.
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
    /// @param tokenOwner The locked token owner.
    /// @param year Years since 2018 the tokens are locked until.
    /// @return Locked token holdings of an address for `(year + 2018)`.
    //-------------------------------------------------------------------------
    function getLockedTokensByYear(
        address tokenOwner, 
        uint year
    ) external view returns (uint) {
        return tokensLockedUntilYear[tokenOwner][year];
    }
}