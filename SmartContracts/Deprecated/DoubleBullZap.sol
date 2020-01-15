pragma solidity ^0.5.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";


interface Invest2Fulcrum2xLongBTC {
    function LetsInvest2Fulcrum2xLongBTC(address _towhomtoissue) external payable;
}

// this is the underlying contract that invests in 2xLongETH on Fulcrum
interface Invest2Fulcrum2xLongETH {
    function LetsInvest2Fulcrum(address _towhomtoissue) external payable;
}


// through this contract we are putting 50% allocation to 2xLongETH and 50% to 2xLongBTC
contract DoubleBullZap is Ownable {
    using SafeMath for uint;
    // state variables
    
    
    // - variables in relation to the percentages
    uint public BTC2xLongPercentage = 50;
    Invest2Fulcrum2xLongETH public Invest2Fulcrum2xLong_ETHContract = Invest2Fulcrum2xLongETH(0xAB58BBF6B6ca1B064aa59113AeA204F554E8fBAe);
    Invest2Fulcrum2xLongBTC public Invest2Fulcrum2xLong_BTCContract = Invest2Fulcrum2xLongBTC(0xd455e7368BcaB144C2944aD679E4Aa10bB3766c1);

    
    // - in relation to the ETH held by this contract
    uint public balance = address(this).balance;
    
    // - in relation to the emergency functioning of this contract
    bool private stopped = false;

    
    // circuit breaker modifiers
    modifier stopInEmergency {if (!stopped) _;}
    modifier onlyInEmergency {if (stopped) _;}
    
 

    // this function should be called should we ever want to change the underlying Fulcrum Long ETHContract address
    function set_Invest2Fulcrum2xLong_ETHContract (Invest2Fulcrum2xLongETH _Invest2Fulcrum2xLong_ETHContract) onlyOwner public {
        Invest2Fulcrum2xLong_ETHContract = _Invest2Fulcrum2xLong_ETHContract;
    }
    
    // this function should be called should we ever want to change the underlying Fulcrum Long ETHContract address
    function set_Invest2Fulcrum2xLong_BTCContract (Invest2Fulcrum2xLongBTC _Invest2Fulcrum2xLong_BTCContract) onlyOwner public {
        Invest2Fulcrum2xLong_BTCContract = _Invest2Fulcrum2xLong_BTCContract;
    }
    
    // this function should be called should we ever want to change the portion to be invested in 2xLongBTC
    function set_BTC2xLongPercentage (uint32 _BTC2xLongPercentage) onlyOwner public {
        BTC2xLongPercentage = _BTC2xLongPercentage;
    }
    
    // main function which will make the investments
    function LetsInvest() public payable returns(uint) {
        require (msg.value > 100000000000000);
        require (msg.sender != address(0));
        uint invest_amt = msg.value;
        address payable investor = address(msg.sender);
        uint BTC2xLongPortion = SafeMath.div(SafeMath.mul(invest_amt,BTC2xLongPercentage),100);
        uint ETH2xLongPortion = SafeMath.sub(invest_amt, BTC2xLongPortion);
        require (SafeMath.sub(invest_amt, SafeMath.add(BTC2xLongPortion, ETH2xLongPortion)) ==0 );
        Invest2Fulcrum2xLong_BTCContract.LetsInvest2Fulcrum2xLongBTC.value(BTC2xLongPortion)(investor);
        Invest2Fulcrum2xLong_ETHContract.LetsInvest2Fulcrum.value(ETH2xLongPortion)(investor);
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
            LetsInvest();
        }
    }
    
    // - to withdraw any ETH balance sitting in the contract
    function withdraw() onlyOwner public{
        owner.transfer(address(this).balance);
    }
    
}