pragma solidity ^0.5.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";


interface ERC20 {
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
}


interface SynthDepotInterface {
      function exchangeEtherForSynths() external payable returns (uint256);
      
}

contract SynthProxyInterface{
    function exchange(bytes32 sourceCurrencyKey, uint256 sourceAmount, bytes32 destinationCurrencyKey, address destinationAddress) external returns (bool);
}

contract Invest2_sBTC is Ownable {
    using SafeMath for uint;
    
    SynthDepotInterface public SynthDepotInterfaceContract = SynthDepotInterface(0x172E09691DfBbC035E37c73B62095caa16Ee2388);
    SynthProxyInterface public SynthProxyInterfaceContract = SynthProxyInterface(0xC011A72400E58ecD99Ee497CF89E3775d4bd732F);
    ERC20 public sBTCContract = ERC20(0xfE18be6b3Bd88A2D2A7f928d00292E7a9963CfC6);
    
    bytes32 USDbytes32= 0x7355534400000000000000000000000000000000000000000000000000000000;
    bytes32 sBTCbytes32= 0x7342544300000000000000000000000000000000000000000000000000000000;


    // - variable for tracking the ETH balance of this contract
    uint public balance;

    // this function should be called should we ever want to change the Synthetix Depot address
    function set_SynthDepotInterfaceContract(SynthDepotInterface _SynthDepotInterfaceContract) onlyOwner public {
        SynthDepotInterfaceContract = _SynthDepotInterfaceContract;
    }
    
    // this function should be called should we ever want to change the Synthetix Proxy address
    function set_SynthProxyInterfaceContract(SynthProxyInterface _SynthProxyInterfaceContract) onlyOwner public {
        SynthProxyInterfaceContract = _SynthProxyInterfaceContract;
    }
    
    // this function should be called should we ever want to change the sBTC Contract address
    function set_sBTCContract(ERC20 _sBTCContract) onlyOwner public {
        sBTCContract = _sBTCContract;
    }
    
    function LetsInvestin_sBTC(address payable _investor) public payable returns(uint) {
        require(_investor != address(0));
        uint invest_amt = msg.value;
        require (msg.value > 100000000000000);
        uint sUSDAmount = SynthDepotInterfaceContract.exchangeEtherForSynths.value(invest_amt)();
        SynthProxyInterfaceContract.exchange(USDbytes32, sUSDAmount, sBTCbytes32, address(this)); 
        uint sBTCUnits = sBTCContract.balanceOf(address(this));
        sBTCContract.transfer(address(_investor),sBTCUnits);
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
            LetsInvestin_sBTC(msg.sender);
        }
    }
    
    // - to withdraw any ETH balance sitting in the contract
    function withdraw() onlyOwner public{
        owner.transfer(address(this).balance);
    }
    
    
 
}