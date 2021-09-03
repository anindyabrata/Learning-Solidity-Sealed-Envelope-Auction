// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract ExampleTokenContract{
    mapping(uint256 => address) ownedBy;
    mapping(uint256 => address) createdBy;
    mapping(uint256 => string) hashOf;
    mapping(address => uint256) lastminted;
    uint256 tokenNext;
    constructor(){
        tokenNext = 1;
    }
    
    // Mint new token
    function mint(string memory hash) public{
        uint256 tid = tokenNext;
        require(ownedBy[tid] == address(0), "Failed to create token");
        tokenNext += 1;
        createdBy[tid] = msg.sender;
        hashOf[tid] = hash;
        ownedBy[tid] = msg.sender;
        lastminted[msg.sender] = tid;
    }
    
    // Get token id
    function lastSenderMintedToken() public view returns (uint256){
        return lastminted[msg.sender];
    }
    
    // Send token
    // Called by token owner
    function sendToken(uint256 tokenid, address to) public{
        require(ownedBy[tokenid] != address(0), "Token does not exist");
        require(ownedBy[tokenid] == msg.sender, "Unauthorized transaction");
        ownedBy[tokenid] = to;
    }
    
    // Receive token
    // Called by recipient
    // Initiated by sender
    function receiveToken(uint256 tokenid) public{
        require(ownedBy[tokenid] != address(0), "Token does not exist");
        require(ownedBy[tokenid] == tx.origin, "Unauthorized transaction");
        ownedBy[tokenid] = msg.sender;
    }
    function ownerOf(uint256 tokenid) public view returns (address){
        return ownedBy[tokenid];
    }
    function isOwnedBy(uint256 tokenid, address owner) public view returns (bool){
        return ownedBy[tokenid] == owner;
    }
    function contentOf(uint256 tokenid) public view returns (string memory){
        return hashOf[tokenid];
    }
    function creatorOf(uint256 tokenid) public view returns (address){
        return createdBy[tokenid];
    }
}
