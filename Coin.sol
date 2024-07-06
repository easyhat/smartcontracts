// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

contract Coin{
    address public minter;
    mapping (address => uint) public balances;

    // event send from  => to
    event Sent(address from, address to, uint amount);
    constructor(){
        minter = msg.sender;
    }

    function mint(address receiver, uint amount) public {
        require(msg.sender == minter);
        balances[receiver] += amount;
    }
    error InsufficientBalance(uint requested, uint available);

    function Send(address receiver, uint amount) public {
        if(amount > balances[msg.sender]){
            revert InsufficientBalance(amount, balances[msg.sender]);
        }
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit  Sent(msg.sender, receiver, amount);
    }

}
