// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
// erros
error CrowDFunding__ContributorDoesNotGetHisMoney();

contract CrowdFunding {
    address public manager;
    mapping(address => uint256) public contributers;
    uint256 public noOfContributers;
    uint256 public deadline; // timestamp
    uint256 public goal;
    uint256 public raisedAmount;
    uint256 public immutable i_minimumContribution = 100 wei;
    struct Request {
        address payable recipient;
        string description;
        uint256 value;
        bool completed;
        uint256 noOfVoters;
        mapping(address => bool) voters;
    }
    mapping(uint256 => Request) requests;
    uint256 public numRequests;

    // modifier
    modifier onlyManager() {
        require(msg.sender == manager, "Only Manager can call it");
        _;
    }

    // events
    event ContributeEvent(address indexed _sender, uint256 _value);
    event CreateRequestEvent(
        string indexed _description,
        address _recipient,
        uint256 _value
    );
    event MakePaymentEvent(address indexed _recipient, uint256 _value);

    constructor(uint256 _goal, uint256 _deadline) {
        manager = msg.sender;
        goal = _goal;
        deadline = block.timestamp + _deadline;
    }

    function contribute() public payable {
        require(block.timestamp < deadline, "Deadline has passed!");
        require(
            msg.value >= i_minimumContribution,
            "Minmum contribution not met!"
        );

        // if the contributer want to contribute many times will incremented once
        if (contributers[msg.sender] == 0) {
            noOfContributers++;
        }
        // the amount will added to old value
        contributers[msg.sender] += msg.value;
        raisedAmount += msg.value;
        emit ContributeEvent(msg.sender, msg.value);
    }

    receive() external payable {
        contribute();
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getRefund() public {
        require(block.timestamp > deadline && raisedAmount < goal);
        require(contributers[msg.sender] > 0);
        address payable recipient = payable(msg.sender);
        uint256 value = contributers[msg.sender];

        (bool success, ) = recipient.call{value: value}("");
        if (!success) {
            revert CrowDFunding__ContributorDoesNotGetHisMoney();
        }
        // if the contribute get his money back , he can not call getRefund again
        contributers[msg.sender] = 0;
    }

    function createRequest(
        string memory _description,
        uint256 _value,
        address payable _recipient
    ) public payable onlyManager {
        Request storage newRequest = requests[numRequests];
        newRequest.description = _description;
        newRequest.value = _value;
        newRequest.recipient = _recipient;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;
        emit CreateRequestEvent(_description, _recipient, _value);
    }

    function voteRequest(uint256 _noRequest) public {
        require(
            contributers[msg.sender] > 0,
            "You must be a contributer to vote."
        );
        Request storage newRequest = requests[_noRequest];
        require(newRequest.voters[msg.sender] == false, "only vote one time.");
        newRequest.voters[msg.sender] = true;
        newRequest.noOfVoters++;
    }

    function makePaymen(uint256 noRequest) public onlyManager {
        require(raisedAmount >= goal);
        Request storage thisRequest = requests[noRequest];
        require(
            thisRequest.completed == false,
            "This Request has been completed."
        );
        require(
            thisRequest.noOfVoters == noOfContributers / 2,
            "50% of voters should vote on this request"
        );
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;
        emit MakePaymentEvent(thisRequest.recipient, thisRequest.value);
    }
}
