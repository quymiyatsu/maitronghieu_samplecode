/*
This Token Contract implements the standard token functionality (https://github.com/ethereum/EIPs/issues/20)
as well as the following OPTIONAL extras intended for use by humans.

1) Initial Finite Supply (upon creation one specifies how much is minted).
2) In the absence of a token registry: Optional Decimal, Symbol & Name.
3) Optional approveAndCall() functionality to notify a contract if an approval() has occurred.
*/

pragma solidity ^0.4.8;

import "./StandardToken.sol";

contract SIAStandardToken is StandardToken {

    mapping (address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    function SIAStandardToken(
        uint256 _initialSupply,
        string _tokenName,
        string _tokenSymbol
        ) StandardToken(_initialSupply, _tokenName, _tokenSymbol) public {}

    // @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    // @param target Address to be frozen
    // @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    function accountStatus(address target) constant public returns (bool status) {
        return frozenAccount[target];
    }

    function transferAllowance(address _from, address _spender, uint256 _value, bytes _extraData, uint256 category, uint256 rate, string batchNumber) public returns (bool success) {
        require(_spender != 0x0);
        require(!frozenAccount[msg.sender]);                     // Check if sender is frozen
        require(!frozenAccount[_from]);
        require(!frozenAccount[_spender]);
        require(allowance(_from, msg.sender) >= _value);
        allowed[_from][msg.sender] -= _value;
        allowed[_from][_spender] += _value;
        require(_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), _from, _value, this, _extraData));
        Categorized(msg.sender, _spender, _value, category, rate, batchNumber);
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData, uint256 category, uint256 rate, string batchNumber) public returns (bool success) {
        require(!frozenAccount[msg.sender]);                     // Check if sender is frozen
        require(!frozenAccount[_spender]);
        if (approve(_spender, _value)) {
            require(_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
            Categorized(msg.sender, _spender, _value, category, rate, batchNumber);
            return true;
        }
    }

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);                                // Prevent transfer to 0x0 address. Use burn() instead
        require(balances[_from] >= _value);                  // Check if the sender has enough
        require(balances[_to] + _value > balances[_to]);    // Check for overflows
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        balances[_from] -= _value;                          // Subtract from the sender
        balances[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);
    }
}