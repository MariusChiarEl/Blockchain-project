// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import './ProductIdentification.sol';

contract Auction {
    
    address payable internal auction_owner;
    uint256 public auction_start;
    uint256 public auction_end;
    uint256 public highestBid;
    address public highestBidder;
 

    enum auction_state{
        CANCELLED,STARTED
    }

    struct  car{
        string  Brand;
        string  Rnumber;
    }
    
    car public Mycar;
    address[] bidders;

    mapping(address => uint) public bids;
    mapping(address => bool) public hasBid;

    auction_state public STATE;


    modifier an_ongoing_auction() {
        require(block.timestamp <= auction_end && STATE == auction_state.STARTED);
        _;
    }
    
    modifier only_owner() {
        require(msg.sender==auction_owner);
        _;
    }
    
    function bid() public virtual payable returns (bool) {}
    function withdraw() public virtual returns (bool) {}
    function cancel_auction() external virtual returns (bool) {}
    
    event BidEvent(address indexed highestBidder, uint256 highestBid);
    event WithdrawalEvent(address withdrawer, uint256 amount);
    event CanceledEvent(string message, uint256 time);  
    
}

import './SampleToken.sol';

contract MyAuction is Auction {
     SampleToken public tokenContract;  


    constructor (address _productIdentificationAddress, uint _biddingTime, address payable _owner, string memory _brand, string memory _Rnumber, address _tokenContractAddress){
        ProductIdentification PI = ProductIdentification(_productIdentificationAddress);
        require(PI.isBrandRegistered(_brand) == true, "Brand is not registered!");
        auction_owner = _owner;
        auction_start = block.timestamp;
        auction_end = auction_start + _biddingTime*1 hours;
        STATE = auction_state.STARTED;
        Mycar.Brand = _brand;
        Mycar.Rnumber = _Rnumber;

        tokenContract = SampleToken(_tokenContractAddress);
    } 
    
    function get_owner() public view returns(address) {
        return auction_owner;
    }
    
    fallback () external payable {
        
    }
    
    receive () external payable {
        
    }
    
    function bid(uint bid_amount) public an_ongoing_auction returns (bool) {
        require(!hasBid[msg.sender], "You have already placed a bid.");
        require(bid_amount > highestBid,"You can't bid, Make a higher Bid");
        highestBidder = msg.sender;
        highestBid = bid_amount;
        bidders.push(msg.sender);
        bids[msg.sender] = highestBid;
          // marcheaza licitatorul ca fiind licitat 
        hasBid[msg.sender] = true;  
        emit BidEvent(highestBidder,  highestBid);
        tokenContract.transferFrom(msg.sender, address(this), bid_amount);

        return true;
    } 
    
    function cancel_auction() external only_owner an_ongoing_auction override returns (bool) {
    
        STATE = auction_state.CANCELLED;
        emit CanceledEvent("Auction Cancelled", block.timestamp);
        return true;
    }
    
   /* function withdraw() public override returns (bool) {
        
        require(block.timestamp > auction_end || STATE == auction_state.CANCELLED,"You can't withdraw, the auction is still open");
        uint amount;

        amount = bids[msg.sender];
        bids[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit WithdrawalEvent(msg.sender, amount);
        return true;
      
    }
    */

    function withdraw() public override returns (bool) {
    require(block.timestamp > auction_end || STATE == auction_state.CANCELLED, "You can't withdraw, the auction is still open");
    require(msg.sender!=highestBidder,"You are the winner, you can't withdraw!");
    uint tokenAmount = bids[msg.sender];
    bids[msg.sender] = 0;
    emit WithdrawalEvent(msg.sender, tokenAmount);
    tokenContract.transfer(msg.sender, tokenAmount);

    return true;
}
    
    function destruct_auction() external only_owner returns (bool) {
        uint value_to_return;
        require(block.timestamp > auction_end || STATE == auction_state.CANCELLED,"You can't destruct the contract,The auction is still open");
        for(uint i = 0; i < bidders.length; i++)
        {   
            if(bids[bidders[i]] != 0 && bidders[i]!=highestBidder)
               { value_to_return=bids[bidders[i]];
                 bids[bidders[i]]=0;
                tokenContract.transferFrom(auction_owner,bidders[i],value_to_return);
               }
        }

        selfdestruct(auction_owner);
        return true;
    
    } 
}

