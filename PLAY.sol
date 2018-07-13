pragma solidity ^0.4.24;


interface AACFunctionality {
    function mintAndSend(address _to) external;
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


interface PLAYInterface {
    // events
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    // required functions
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    
    // optional functions
    function name() external pure returns (string);
    function symbol() external pure returns (string);
    function decimals() external pure returns (uint8);
}


contract PLAYToken is PLAYInterface {
    // ERC-20 functions
    uint totalPLAY;
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

    function name() external pure returns (string) { return "PLAY"; }
    function symbol() external pure returns (string) { return "PLAY"; }
    function decimals() external pure returns (uint8) { return 0; }
}


contract PLAYFunctionality is PLAYToken, Ownable {
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