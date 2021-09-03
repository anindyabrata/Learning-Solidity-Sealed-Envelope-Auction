Sealed envelope auction in solidity
======
This is a submission for UVic's Blockchain May2021 course project.

A seller deploys this smart contract in order to auction off an item. Sellers bid on the item without disclosing their bid amounts. At the end of bidding phase, sellers disclose their bids. The highest bidder found at the end of disclosing stage may acquire the item. Other bidders are allowed to get their unspent money back.

## How to run
The solidity sources can be run on ethereum's remix platform.  
- Compile and deploy example token contract  
- Mint new token and get the ID  
- Use token id and contract address to deploy auction contract

To run the client side code,  
- Install python3 packages from requirements.txt  
- Install ganache-cli using npm  
- Run ganache-cli -m "demo" (Using mnemonic initialization ensures same private keys are used)  
- Change remix environment to Web3 Provider  
- Copy ABI and deployed contract address to common.py  
- Run bidder clients; For example "python3 client.py 1"
