pragma solidity ^0.5.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";


interface Invest2Fulcrum1xShortBTC {
    function LetsInvest2Fulcrum1xShortBTC(address _towhomtoissue) external payable;
}

interface Invest2Fulcrum {
    function LetsInvest2Fulcrum(address _towhomtoissue) external payable;
}


// through this contract we are putting 90% allocation to cDAI and 10% to 2xLongETH
contract ETHMaximalist is Ownable, ReentrancyGuard {
    using SafeMath for uint;
    
    // state variables
    
    
    // - variables in relation to the percentages
    uint public ShortBTCAllocation = 50;
    Invest2Fulcrum public Invest2FulcrumContract = Invest2Fulcrum(0xAB58BBF6B6ca1B064aa59113AeA204F554E8fBAe);
    Invest2Fulcrum1xShortBTC public Invest2Fulcrum1xShortBTCContract = Invest2Fulcrum1xShortBTC(0xa2C3e380E6c082A003819a2a69086748fe3D15Dd);

    
    
    // - in relation to the ETH held by this contract
    uint public balance = address(this).balance;
    
    // - in relation to the emergency functioning of this contract
    bool private stopped = false;

    
    // circuit breaker modifiers
    modifier stopInEmergency {if (!stopped) _;}
    modifier onlyInEmergency {if (stopped) _;}

    constructor () public {
    }
    
    function toggleContractActive() onlyOwner public {
    stopped = !stopped;
    }
    
    function change_cDAIAllocation(uint _numberPercentageValue) public onlyOwner {
        require(_numberPercentageValue > 1 && _numberPercentageValue < 100);
        ShortBTCAllocation = _numberPercentageValue;
    }
    
    
    // this function lets you deposit ETH into this wallet 
    function ETHMaximalistZAP() stopInEmergency payable public returns (bool) {
        require(msg.value>10000000000000);
        uint investment_amt = msg.value;
        uint investAmt2ShortBTC = SafeMath.div(SafeMath.mul(investment_amt,ShortBTCAllocation), 100);
        uint investAmt2c1xLongETH = SafeMath.sub(investment_amt, investAmt2ShortBTC);
        require (SafeMath.sub(investment_amt,SafeMath.add(investAmt2ShortBTC, investAmt2c1xLongETH)) == 0);
        Invest2Fulcrum1xShortBTCContract.LetsInvest2Fulcrum1xShortBTC.value(investAmt2ShortBTC)(msg.sender);
        Invest2FulcrumContract.LetsInvest2Fulcrum.value(investAmt2c1xLongETH)(msg.sender);
        
    }
    // - this function lets you deposit ETH into this wallet
    function depositETH() payable public onlyOwner returns (uint) {
        balance += msg.value;
    }
    
    // - fallback function let you / anyone send ETH to this wallet without the need to call any function
    function() external payable {
        if (msg.sender == owner) {
            depositETH();
        } else {
            ETHMaximalistZAP();
        }
    }
    
    // - to withdraw any ETH balance sitting in the contract
    function withdraw() onlyOwner public{
        owner.transfer(address(this).balance);
    }
    

}
