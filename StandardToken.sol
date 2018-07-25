/*
 * You should inherit from StandardToken
 *
 * Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
.*/
pragma solidity ^0.4.8;

import "./Token.sol";

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}


contract StandardToken is owned, Token {

    // Fancy name: eg Tien Nguyen
    string public name;

    // An identifier: eg SIA
    string public symbol;

    // There could 1000 base units with 3 decimals.
    // Meaning 0.980 SIA = 980 base units.
    // It's like comparing 1 wei to 1 ether.
    // 18 decimals is the strongly suggested default
    uint8 public decimals = 3;

    // If your token leaves out totalSupply and can issue more tokens as time goes on,
    // you need to check if it doesn't wrap.
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    /* Create category for smart contract function call */
    event Categorized(address _from, address _to, uint256 _value, uint256 category, uint256 rate, string batchNumber);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function StandardToken(
        uint256 _initialSupply,
        string _tokenName,
        string _tokenSymbol
        ) public {
        totalSupply = _initialSupply * 10 ** uint256(decimals);     // Update total supply with the decimal amount
        //totalSupply = _initialSupply;                             // Update total supply with the decimal amount
        balances[msg.sender] = totalSupply;                         // Give the creator all initial tokens
        name = _tokenName;                                          // Set the name for display purposes
        symbol = _tokenSymbol;                                      // Set the symbol for display purposes
        owner = msg.sender;
    }

    /**
     * Transfer tokens
     */
    function transfer(address _to, uint256 _value, uint256 category, uint256 rate, string batchNumber) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        Categorized(msg.sender, _to, _value, category, rate, batchNumber);
        return true;
    }

    /**
     * Transfer tokens from other address
     */
    function transferFrom(address _from, address _to, uint256 _value, uint256 category, uint256 rate, string batchNumber) public returns (bool success) {
        require(_value <= allowed[_from][msg.sender]);     // Check allowance
        allowed[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        Categorized(msg.sender, _to, _value, category, rate, batchNumber);
        return true;
    }

    /**
     * Get balance of other address
     */
    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    /**
     * Set allowance for other address
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] += _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Set allowance for other address
     */
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
     * Get totalSupply of the token
     */
    function totalSupply() constant returns (uint256 supply) {
        return totalSupply;
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint256 _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balances[_from] >= _value);
        // Check for overflows
        require(balances[_to] + _value > balances[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balances[_from] + balances[_to];
        // Subtract from the sender
        balances[_from] -= _value;
        // Add the same to the recipient
        balances[_to] += _value;
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balances[_from] + balances[_to] == previousBalances);
    }
}