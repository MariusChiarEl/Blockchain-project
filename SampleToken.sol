// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SampleToken {
    
    string public name = "Sample Token";
    string public symbol = "TOK";

    uint256 public totalSupply;

    uint8 public decimals = 8; // the token will be devided by 10^(decimals)
    
    event Transfer(address indexed _from,
                   address indexed _to,
                   uint256 _value);

    event Approval(address indexed _owner,
                   address indexed _spender,
                   uint256 _value);

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping(address => uint256)) public allowance;

    constructor (uint256 _initialSupply) {
        balanceOf[msg.sender] = _initialSupply;
        totalSupply = _initialSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function token_name() public view returns (string memory){
        return name;
    }

    function token_symbol() public view returns (string memory){
        return symbol;
    }

    function token_decimals() public view returns (uint8){
        return decimals;
    }

    function total_supply() public view returns (uint256){
        return totalSupply;
    }

    function balance_of(address _owner) public view returns (uint256){
        return balanceOf[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient funds!");

      
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value; 
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from], "don't have enough tokens");
        require(_value <= allowance[_from][msg.sender], "not allowed to transfer so many tokens");
       
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value; 
        
        emit Transfer(_from, _to, _value);
        return true;
    }

    function allowance_left(address _owner, address _spender) public view returns (uint256){
        return allowance[_owner][_spender];
    }
}

contract SampleTokenSale {
    
    SampleToken public tokenContract;
    uint256 public tokenPrice;
    address owner;

    uint256 public tokensSold;

    event Sell(address indexed _buyer, uint256 indexed _amount);

    constructor(SampleToken _tokenContract, uint256 _tokenPrice) {
        owner = msg.sender;
        tokenContract = _tokenContract;
        tokenPrice = _tokenPrice;
    }

    // modificarea pretului de vanzare fixat la instantierea contractului 
    function updatePrice(uint _tokenPrice) external {
        require(msg.sender == owner, "not allowed to change price");
        tokenPrice = _tokenPrice;
    }

    function buyTokens(uint256 _numberOfTokens) public payable {
        // >= instead of ==
        require(msg.value >= _numberOfTokens * tokenPrice);
        // allowance
        // require(tokenContract.allowance_left(owner, address(this)) >= _numberOfTokens);
        // require(tokenContract.balanceOf(address(this)) >= _numberOfTokens);
        require(tokenContract.transferFrom(owner, msg.sender, _numberOfTokens));

        // restul este returnat 
        if (msg.value - _numberOfTokens * tokenPrice > 0){
            payable(msg.sender).transfer(msg.value - _numberOfTokens * tokenPrice);
        }
        
        emit Sell(msg.sender, _numberOfTokens);
        tokensSold += _numberOfTokens;
        // tokenContract.approve(msg.sender, _numberOfTokens);
        // in schimbul ether-ului cheltuit, clientului ii vor fi aprobate cheltuirea numarului de monede cumparate
    }

    function endSale() public {
        require(tokenContract.transfer(owner, tokenContract.balanceOf(address(this))));
        require(msg.sender == owner);
        payable(msg.sender).transfer(address(this).balance);
    }
}
