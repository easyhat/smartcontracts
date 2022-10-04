// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

contract AuctionCreator{
    address[] public deployedAuctions;
    // create Auction Instance
    function createAuction(uint256 endBlock) public {
        address newAuction =  address(new Auction(msg.sender,endBlock));
        deployedAuctions.push(newAuction); 
    }
    // get All Auctions 
    function allAuctions() public view returns (address[] memory){
        return deployedAuctions;
    }
}

// errors
error Auction__FailedTosendMoney();
contract Auction{
    // states
    address payable public  seller;
    uint256 public startBlock;
    uint256 public endBlock;
    string public ipfsHash;
    enum State{Started, Running, Ended, Canceled}
    State public auctionState;
    uint256 public minBid = 0.02 ether;
    uint256 public  highestBindingBid;
    address payable public highestBidder;
    mapping (address=>uint256) public bids;
    uint256 bidIncrement;
    // modifiers
    modifier notSeller(){
        require(msg.sender != seller);
        _;
    }
    modifier afterStart(){
        require(block.number >= startBlock);
        _;
    }
    modifier beforeEnd(){
        require(block.number <= endBlock);
        _;
    }
    modifier  onlySeller(){
        require(seller == msg.sender);
        _;
    }
    // constructor
    constructor(address _seller,uint256 _endblock){
        seller = payable(_seller);
        auctionState = State.Running;
        startBlock = block.timestamp;
        endBlock = startBlock + _endblock; // _endblock is a time when the auction will end/ 15
        ipfsHash = "";
        bidIncrement = 20000000000000000; // 0.02
    }
    
    function min(uint a, uint b) pure internal returns(uint){
        if(a <= b){
            return a;
        } else {
            return b;
        }
    }
    // cancel an auction
    function cancelAuction() public onlySeller{
        // change auction State to Canceled
        auctionState = State.Canceled;
    }
    // place a bid on auction
    function placeBid() public payable  notSeller afterStart beforeEnd{
        require(auctionState == State.Running, "The Auction state should be Running.");
        require(msg.value >= minBid);
        uint256 currentBid = bids[msg.sender] + msg.value;
        require(currentBid > highestBindingBid);
        bids[msg.sender] = currentBid;
        if(currentBid <= bids[highestBidder]){
            highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
        } else {
            highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
            highestBidder = payable(msg.sender);
        }

    }

    //finalize the auction
    function finalizeAuction() public {
        require(auctionState == State.Canceled || block.number > endBlock);
        require(msg.sender == seller || bids[msg.sender] > 0);
        address payable recipient;
        uint256 value;

        if(auctionState == State.Canceled) { // Auction was canceled
            recipient = payable (msg.sender);
            value = bids[msg.sender];
        } else { // Auction was ended (not canceled)
            if(msg.sender == seller){ // this is the seller
                recipient = seller;
                value = highestBindingBid;
            } else { // this is a bidder
                if(msg.sender == highestBidder) {
                    recipient = highestBidder;
                    value = bids[highestBidder] - highestBindingBid;
                } else { // this is neither the seller nor the highestBidder
                    recipient = payable (msg.sender);
                    value = bids[msg.sender];
                }
            }
        }
        // resetting recipient

        // send money to recipient
        (bool success,) = recipient.call{value:value}("");
        if (!success){
            revert Auction__FailedTosendMoney();
        }
    }



}