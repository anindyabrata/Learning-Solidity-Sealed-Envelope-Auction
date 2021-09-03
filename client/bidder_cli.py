from common import *
import time, sys
from rich.console import Console
from web3.auto import w3
import web3

bid_amount = [0, 30, 15, 20]
bid_cost =   [0, 50, 50, 50]
bid_secret = [0, 1, 2, 3]

def main():
    index = int(sys.argv[1])
    w3.eth.defaultAccount = w3.eth.accounts[index]
    me = w3.eth.accounts[index]
    bid_hash = web3.Web3.solidityKeccak(["uint256", "bool", "uint256"], [bid_amount[index], False, bid_secret[index]])
    console = Console()
    console.print("commitment hash: ", bid_hash.hex(), type(bid_hash))
    #console.print(w3.eth.accounts)
    #console.print(dir(w3.eth))
    #console.print(w3.isConnected())
    SEAcontract = w3.eth.contract(address=sea_addr, abi=sea_abi)
    initial_stage = SEAcontract.functions.getStage().call()
    assert(initial_stage == 0)
    initial_stage = Stage[initial_stage]
    #console.print(initial_stage)
    #console.print(dir(SEAcontract.events.stateChanged()))
    #blk_filter = w3.eth.filter({"address": addr})
    stateChangedFilter = SEAcontract.events.stateChanged.createFilter(fromBlock="latest", topics=[])
    bidPlacedEventFilter = SEAcontract.events.bidPlaced.createFilter(fromBlock="latest", topics=[])
    bidDisclosedEventFilter = SEAcontract.events.bidDisclosed.createFilter(fromBlock="latest", topics=[])
    debugEF = SEAcontract.events.debug.createFilter(fromBlock="latest", topics=[])
    stat_str = "[bold green]At stage: [/bold green] "
    with console.status(stat_str + initial_stage) as status:
        while(True):
            #status.update(stat_str + "[blue]" + str(i) + "[/blue]")
            for event in stateChangedFilter.get_new_entries():
                # console.print(event)
                #console.print(SEAcontract.events.stateChanged().processReceipt(event))
                #console.print(SEAcontract.events.stateChanged().processLog(event))
                #processed_event = SEAcontract.events.stateChanged().processReceipt(event)
                st = event.args._st#['args']['_st']
                status.update(stat_str + Stage[st])
                if st == 1:
                    console.print("placebid")
                    txn = SEAcontract.functions.bid(bid_hash).transact({"from": me, "value": web3.Web3.toWei(bid_cost[index], "ether")})
                    console.print(txn)
                elif st == 2:
                    console.print("disclose")
                    txn = SEAcontract.functions.disclose(bid_amount[index], False, bid_secret[index]).call()
                    console.print(txn)
                elif st == 3:
                    console.print("withdraw")
                    txn = SEAcontract.functions.withdraw().transact()
                    console.print(txn)
            for event in bidPlacedEventFilter.get_new_entries():
                hsh = event.args.hash
                console.print(hsh.hex())
            for event in bidDisclosedEventFilter.get_new_entries():
                amnt = event.args.amount
                console.print(amnt)
            for event in debugEF.get_new_entries():
                one, two = event.args.one, event.args.two
                console.print(one.hex(), two.hex())
            time.sleep(.1)
    print("Done")

if __name__ == "__main__":
    main()
