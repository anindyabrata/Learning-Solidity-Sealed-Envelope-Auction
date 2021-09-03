// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// Contract that handles ownership of auction item
interface ITokenContract{
    function sendToken(uint256 tokenid, address to) external;
    function receiveToken(uint256 tokenid) external;
}

contract SEAuction{
    enum Stage { Created, Bidding, Disclosing, Withdrawing, Ended }
    Stage stage;
    
    address public winner;
    address seller;
    uint creation_time;
    uint max_stage_dur;
    uint256 public auction_item;
    address token_contract_addr;
    
    mapping(address => bytes32[]) bidder_hashes;
    mapping(address => uint) bidder_balance;
    
    uint public highest_bid = 0;
    address highest_bidder;
    
    error Unauthorized();
    error IncorrectStage(Stage correct);
    
    event stateChanged(Stage _st);
    event bidPlaced(bytes32 hash);
    event bidDisclosed(uint amount);
    event winnerAnnounced(address winner_address);
    event bidCanceled();
    
    modifier onlySeller(){
        if(msg.sender != seller) revert Unauthorized();
        _;
    }
    
    modifier atStage(Stage current, Stage desired) {
        if (current != desired) revert IncorrectStage(desired);
        _;
    }
    
    modifier beforeStage(Stage current, Stage desired) {
        if (uint(current) >= uint(desired)) revert IncorrectStage(Stage(uint(desired) - 1));
        _;
    }
    
    // Construct the contract with duration, item to sell and item contract specified
    // Ownership of item to be sold is transferred to the auction contract
    constructor(uint max_stage_duration, uint256 auctionItem, address _itoken_address){
        creation_time = block.timestamp;
        seller = msg.sender;
        stage = Stage.Created;
        max_stage_dur = max_stage_duration * 1 days;
        auction_item = auctionItem;
        token_contract_addr = _itoken_address;
        ITokenContract(token_contract_addr).receiveToken(auction_item);
    }
    
    // Determines the current stage
    // If change in stage is encountered, transition is performed
    function getStage() public returns(Stage){
        Stage old = stage;
        Stage cs = getCalcStage();
        if(uint(cs) > uint(stage)) setStage(cs);
        if(old != stage){
            stageChange(old, stage);
        }
        return stage;
    }
    
    // Called when stage is changed
    function stageChange(Stage oldstage, Stage newstage) private{
        if(oldstage == Stage.Disclosing && newstage == Stage.Withdrawing){
            if(highest_bid > 0){
                winner = highest_bidder;
                bidder_balance[winner] -= highest_bid;
                bidder_balance[seller] += highest_bid;
                emit winnerAnnounced(highest_bidder);
            }
        }
        emit stateChanged(newstage);
    }
    
    // Determines what stage it should be according to current time
    function getCalcStage() private view returns(Stage){
        uint256 ret = (block.timestamp - creation_time) / max_stage_dur;
        if(ret > uint256(Stage.Ended)) return Stage.Ended;
        return Stage(ret);
    }
    
    // Manually set the stage to st
    function setStage(Stage st) private onlySeller beforeStage(getStage(), st){
        Stage old = getStage();
        stage = st;
        stageChange(old, st);
    }
    
    // Transition to the next stage
    function nextStage() public onlySeller{ // only seller allowed to call
        if(stage != Stage.Ended){
            setStage(Stage(1 + uint(stage)));
        }
    }
    
    // Place a bid
    // Takes commitment hash as input and receives ether
    function bid(bytes32 hashed_value) public payable atStage(getStage(), Stage.Bidding) {
        bidder_hashes[msg.sender].push(hashed_value);
        bidder_balance[msg.sender] += msg.value; // default is 0?
        emit bidPlaced(hashed_value);
    }
    
    // Disclose a bid placed previously
    // disclosed bid is verified and highest bidder is updated
    function disclose(uint value, bool fake, uint secret) public atStage(getStage(), Stage.Disclosing) {
        bytes32 calculated_hash = commitment(value, fake, secret);
        for (uint i = 0; i < bidder_hashes[msg.sender].length; i++) {
            if(calculated_hash == bidder_hashes[msg.sender][i] && !fake && value < bidder_balance[msg.sender]){
                // update highest bid
                if(value > highest_bid){
                    highest_bid = value;
                    highest_bidder = msg.sender;
                }
                emit bidDisclosed(value);
            }
        }
    }
    
    // Withdrawing auction item/unused bid payment
    // seller receives price paid for item
    function withdraw() public payable atStage(getStage(), Stage.Withdrawing) returns (uint){
        if(msg.sender == winner) ITokenContract(token_contract_addr).sendToken(auction_item, msg.sender);
        if(winner == address(0) && msg.sender == seller) ITokenContract(token_contract_addr).sendToken(auction_item, msg.sender);
        uint balance = bidder_balance[msg.sender];
        if(balance > 0){
            bidder_balance[msg.sender] = 0;
            payable(msg.sender).transfer(balance);
        }
        return balance;
    }
    
    // Hash used to verify bid commitment
    // A similar hash should be implemented by client
    function commitment(uint value, bool fake, uint secret) private pure returns (bytes32){ // only using public for debug. Should be private
        return keccak256(abi.encodePacked(value, fake, secret));
    }
    
    // Cancel the auction
    function cancel_auction() public payable beforeStage(getStage(), Stage.Withdrawing) onlySeller{
        setStage(Stage.Withdrawing);
        emit bidCanceled();
    }
    
    // Determine if auction is succesfuly completed
    function isSuccessful() public atStage(getStage(), Stage.Ended) returns (bool){
        return winner != address(0);
    }
}
