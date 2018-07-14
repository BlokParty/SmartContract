pragma solidity ^0.4.24;

interface PLAYInterface {
    // events
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    // ERC-721 required functions
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    
    // ERC-721 optional functions
    function name() external pure returns (string);
    function symbol() external pure returns (string);
    function decimals() external pure returns (uint8);

    // other PLAY functions
    function burn(uint tokens) external returns (bool success);
    function burnFrom(address from, uint tokens) external returns (bool success);

    function getTotalLockedTokens (address from) external view returns (uint lockedTokens);
    function getLockedTokensByYear (address from, uint year) external view returns (uint);
    function lockUntil(uint numberOfYears, uint tokens) external;
    function lockUntilFrom(address from, uint numberOfYears, uint tokens) external;
    function unlockAll(address unlockAddress) external;
    function unlockByYear(address from, uint year) external;
    function updateYearsSinceRelease() external;
    
    function getColoredTokenBalance(address tokenOwner, uint tokenColor) external view returns (uint);
    function color(uint tokenColor, uint tokens) external;
    function uncolor(uint tokenColor, uint tokens) external;
    
}


contract PLAYToken is PLAYInterface {
    // ERC-20 functions
    uint totalPLAY = 1000000000;    // one billion
    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowances;

    function transfer(address to, uint tokens) external returns (bool success) {
        require (balances[msg.sender] >= tokens);
        require (to != 0);
        balances[msg.sender] -= tokens;
        balances[to] += tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) external returns (bool success) {
        allowances[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) external returns (bool success) {
        require (allowances[from][msg.sender] >= tokens);
        require (balances[from] >= tokens);
        allowances[from][msg.sender] -= tokens;
        balances[from] -= tokens;
        balances[to] += tokens;
        emit Transfer(from, to, tokens);
        return true;
    }

    function totalSupply() external view returns (uint) {
        return totalPLAY;
    }
    function balanceOf(address tokenOwner) public view returns (uint) {
        require (tokenOwner != 0);
        return balances[tokenOwner];
    }
    function allowance(address tokenOwner, address spender) public view returns (uint) {
        return allowances[tokenOwner][spender];
    }

    function name() external pure returns (string) { return "People Like All Your Network"; }   // please change before release
    function symbol() external pure returns (string) { return "PLAY"; }
    function decimals() external pure returns (uint8) { return 0; }
}


contract BurnPLAY is PLAYToken {
    // Burn functions
    // for safety, tokens cannot be transferred to the 0 address unless burn is explicitly called
    function burn(uint tokens) external returns (bool success) {
        require (balances[msg.sender] >= tokens);
        balances[msg.sender] -= tokens;
        emit Transfer(msg.sender, address(0), tokens);
        return true;
    }

    function burnFrom(address from, uint tokens) external returns (bool success) {
        require (allowances[from][msg.sender] >= tokens);
        require (balances[from] >= tokens);
        allowances[from][msg.sender] -= tokens;
        balances[from] -= tokens;
        emit Transfer(from, address(0), tokens);
        return true;
    }
}

contract LockPLAY is BurnPLAY {
    // Lock functions
    uint constant firstYearTimestamp = 1514764800; // 1-1-2018 00:00:00
    uint public yearsSinceRelease;
    uint public maximumLockYears = 10;
    mapping (address => mapping(uint => uint)) lockedUntilYearTokens;

    function lockUntil(uint numberOfYears, uint tokens) external {
        require (numberOfYears > 0 && numberOfYears <= maximumLockYears);
        require (balances[msg.sender] >= tokens);

        balances[msg.sender] -= tokens;
        lockedUntilYearTokens[msg.sender][yearsSinceRelease + numberOfYears] += tokens;
    }

    function lockUntilFrom(address from, uint numberOfYears, uint tokens) external {
        require (numberOfYears > 0 && numberOfYears <= maximumLockYears);
        require (allowances[from][msg.sender] >= tokens);
        require (balances[from] >= tokens);

        allowances[from][msg.sender] -= tokens;
        balances[from] -= tokens;
        lockedUntilYearTokens[from][yearsSinceRelease + numberOfYears] += tokens;
    }

    function unlockAll(address tokenOwner) external {
        address addressToUnlock = tokenOwner;
        if(addressToUnlock == address(0)) {
            addressToUnlock = msg.sender;
        }
        for(uint i = 0; i <= yearsSinceRelease; ++i) {
            balances[addressToUnlock] += lockedUntilYearTokens[addressToUnlock][i];
            lockedUntilYearTokens[addressToUnlock][i] = 0;
        }
    }

    function unlockByYear(address tokenOwner, uint year) external {
        require(yearsSinceRelease >= year);
        balances[tokenOwner] += lockedUntilYearTokens[tokenOwner][year];
        lockedUntilYearTokens[tokenOwner][year] = 0;
    }

    function getTotalLockedTokens (address tokenOwner) external view returns (uint lockedTokens) {
        for (uint i = 0; i < yearsSinceRelease + maximumLockYears; ++i) {
            lockedTokens += lockedUntilYearTokens[tokenOwner][i];
        }
    }

    function getLockedTokensByYear (address tokenOwner, uint year) external view returns (uint) {
        return lockedUntilYearTokens[tokenOwner][year];
    }

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


contract ColorPLAY is LockPLAY, Ownable {    
    // Color functions
    mapping (address => mapping(uint => uint)) coloredTokens;
    mapping (uint => address) colorToOwner;

    function getColoredTokenBalance(address tokenOwner, uint tokenColor) external view returns (uint) {
        return coloredTokens[tokenOwner][tokenColor];
    }

    function color(uint tokenColor, uint tokens) external {
        require (balances[msg.sender] >= tokens);
        coloredTokens[msg.sender][tokenColor] += tokens;
        balances[msg.sender] -= tokens;
    }

    function colorFrom(address from, uint tokenColor, uint tokens) external {
        require (allowances[from][msg.sender] >= tokens);
        require (balances[from] >= tokens);
        
        allowances[from][msg.sender] -= tokens;
        coloredTokens[from][tokenColor] += tokens;
        balances[msg.sender] -= tokens;
    }

    function uncolor(uint tokenColor, uint tokens) external {
        require(msg.sender == colorToOwner[tokenColor]);
        require(tokens <= coloredTokens[msg.sender][tokenColor]);
        balances[msg.sender] += tokens;
        coloredTokens[msg.sender][tokenColor] -= tokens;
    }
}


interface AACFunctionality {
    function mintAndSend(address _to) external;
}


contract PLAYFunctionality is ColorPLAY {
    mapping (address => uint) spentPLAY;
    uint spenderCount;
    mapping (uint => address) spenders;
    mapping (address => bool) hasSpent;

    uint public mintPrice;
    address aacAddress;

    AACFunctionality aacMinter = AACFunctionality(aacAddress);

    function spendAndMintAndSend(address _to) external {
        require(balances[msg.sender] >= mintPrice);
        balances[msg.sender] -= mintPrice;
        spentPLAY[msg.sender] += mintPrice;
        if (hasSpent[msg.sender] == false) {
            spenders[spenderCount] = msg.sender;
            hasSpent[msg.sender] = true;
            spenderCount++;
        }
        aacMinter.mintAndSend(_to);
    }

    function newMintPeriod(uint _newMintPrice) external onlyOwner {
        // reset spent PLAY
        for(uint i = 0; i < spenderCount; ++i) {
            balances[spenders[i]] += spentPLAY[spenders[i]];
            spentPLAY[spenders[i]] = 0;
            hasSpent[spenders[i]] = false;
        }
        spenderCount = 0;
        
        // set new mint price
        mintPrice = _newMintPrice;
    }
}