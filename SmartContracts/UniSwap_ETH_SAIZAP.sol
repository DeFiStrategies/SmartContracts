pragma solidity ^0.5.0;

import './OpenZepplinOwnable.sol';
import './OpenZepplinSafeMath.sol';
import './OpenZepplinIERC20.sol';
import './OpenZepplinReentrancyGuard.sol';

// the objective of this contract is only to get the exchange price of the assets from the uniswap indexed

interface UniSwapAddLiquityV2_General {
    function LetsInvest(address _TokenContractAddress, address _towhomtoissue) external payable returns (uint);
}

contract UniSwap_ETH_SAIZap is Ownable, ReentrancyGuard {
    using SafeMath for uint;

    // state variables
    uint public balance = address(this).balance;
    
    
    // in relation to the emergency functioning of this contract
    bool private stopped = false;
     
    // circuit breaker modifiers
    modifier stopInEmergency {if (!stopped) _;}
    modifier onlyInEmergency {if (stopped) _;}
    
    address public SAI_TokenContractAddress;
    UniSwapAddLiquityV2_General public UniSwapAddLiquityV2_GeneralAddress;
    

    constructor(address _SAI_TokenContractAddress, UniSwapAddLiquityV2_General _UniSwapAddLiquityV2_GeneralAddress ) public {
        SAI_TokenContractAddress = _SAI_TokenContractAddress;
        UniSwapAddLiquityV2_GeneralAddress = _UniSwapAddLiquityV2_GeneralAddress;
    }

    function set_new_SAI_TokenContractAddress(address _new_SAI_TokenContractAddress) public onlyOwner {
        SAI_TokenContractAddress = _new_SAI_TokenContractAddress;
    }

    function set_new_UniSwapAddLiquityV2_GeneralAddress(UniSwapAddLiquityV2_General _new_UniSwapAddLiquityV2_GeneralAddress) public onlyOwner {
        UniSwapAddLiquityV2_GeneralAddress = _new_UniSwapAddLiquityV2_GeneralAddress;
    }

    function LetsInvest() public payable stopInEmergency {
        UniSwapAddLiquityV2_GeneralAddress.LetsInvest.value(msg.value)(SAI_TokenContractAddress, address(msg.sender));

    }


    // - this function lets you deposit ETH into this wallet
    function depositETH() public payable  onlyOwner {
        balance += msg.value;
    }
    
    // - fallback function let you / anyone send ETH to this wallet without the need to call any function
    function() external payable {
        if (msg.sender == _owner) {
            depositETH();
        } else {
            LetsInvest();
        }
    }
    
    // - to withdraw any ETH balance sitting in the contract
    function withdraw() public onlyOwner {
        _owner.transfer(address(this).balance);
    }


}