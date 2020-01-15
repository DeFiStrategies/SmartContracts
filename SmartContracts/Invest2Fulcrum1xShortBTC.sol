pragma solidity ^0.5.0;

contract fulcrumInterface {
    function mintWithEther(address receiver, uint256 maxPriceAllowed) external payable returns (uint256 mintAmount);
    function mint(address receiver, uint256 amount) external payable returns (uint256 mintAmount);
    function burnToEther(address receiver, uint256 burnAmount, uint256 minPriceAllowed) external returns (uint256 loanAmountPaid);
}

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract Invest2Fulcrum1xShortBTC is Ownable, ReentrancyGuard {
    // this is a basic version of the contract that we will use to take ETH and invest in fulcrum 1x Short BTC product
    
    // function architechture
    // - collect ETH from user
    // - invest in fulcrum with Ether from user
    // - send back the pToken to the ultimate user
    
    // state variables
    uint public balance;
    uint public maxPrice = 100000000000000000000000000;
    fulcrumInterface public fulcrumInterfaceContract = fulcrumInterface(0x9fC208947d92B1588F7BdE245620439568A8587a);
    
    // events
    event AmountInvested(string successmessage, uint numberOfTokensIssued);
    
    // fx in relation to invest with ETH in fulcrum
    
     // - should we ever want to change the interface contract
    function set_fulcrumInterface(fulcrumInterface _fulcrumInterfaceContract) onlyOwner public {
        fulcrumInterfaceContract = _fulcrumInterfaceContract;
    }
    
    
    // - this is to control the slippage
    function set_maxPrice(uint _insertETHValueonly) onlyOwner public {
        maxPrice = _insertETHValueonly;
    }
    
    //  - the investment fx
    function LetsInvest2Fulcrum1xShortBTC(address _towhomtoissue) payable public  {
        require(_towhomtoissue != address(0));
        uint amountToBeInvested = msg.value;
        uint tokensIssued = fulcrumInterfaceContract.mintWithEther.value(amountToBeInvested)(address(_towhomtoissue), maxPrice);
        emit AmountInvested("Done! the number of pTokens issued are: ", tokensIssued);
        
    }
    
    
    // fx in relation to ETH held by the contract sent by the owner
    
    // - this function lets you deposit ETH into this wallet
    function depositETH() payable public onlyOwner returns (uint) {
        balance += msg.value;
    }
    
    // - fallback function let you / anyone send ETH to this wallet without the need to call any function
    function() external payable {
        if (msg.sender == owner) {
            depositETH();
        } else {
            LetsInvest2Fulcrum1xShortBTC(msg.sender);
        }
    }
    
    // - to withdraw any ETH balance sitting in the contract
    function withdraw() onlyOwner public{
        owner.transfer(address(this).balance);
    }
    
    
}