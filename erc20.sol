// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function transfer(address recipient, uint256 tokens) external returns (bool success);

    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);
    function approve(address spender, uint256 tokens) external returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed  to, uint256 tokens);
    event Approval(address indexed tokenOwer, address indexed spender, uint256 tokens);
}

contract Cryptos is IERC20{
    string public name = "Cryptos";
    string public symbol = "CRT";
    uint256 public decimals = 0; // 18
    uint256 public override totalSupply;

    address public founder;
    mapping (address => uint256) public balances;
    mapping(address => mapping (address => uint256)) allowed; // [0x111] owner allows ... 0x222 (spender) 100 token
    // allowed[0x111][0x222] = 100 like this
    constructor(){
        totalSupply = 1000000;
        founder = msg.sender;
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address tokenOwer) public view override returns(uint256 balance){
        return balances[tokenOwer];
    }

    function transfer(address recipient, uint256 tokens) public override  returns (bool success){
        require(balances[msg.sender] > tokens);
        balances[recipient] += tokens;
        balances[msg.sender] -= tokens;
        emit Transfer(msg.sender,recipient, tokens);
        return true;
    }
    function allowance(address tokenOwner, address spender) public override  view returns (uint256){
         return allowed[tokenOwner][spender];
    }
    function approve(address spender, uint256 tokens) public override returns (bool success){
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);

        return true;
    }
    function transferFrom(address from, address to, uint256 tokens) public override  returns (bool success){
        require(allowed[from][msg.sender] >= tokens);
        require(balances[from] >= tokens);
        balances[from] -= tokens;
        allowed[from][msg.sender] -= tokens;
        balances[to] += tokens;
        emit Transfer(from, to, tokens);
        return true;
    }


}