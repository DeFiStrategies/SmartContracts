pragma solidity ^0.5.0;

import "./OpenZepplinOwnable.sol";
import "./OpenZepplinReentrancyGuard.sol";
import "./OpenZepplinSafeMath.sol";
import "./OpenZepplinIERC20.sol";

interface fulcrumInterface {
    function mintWithEther(address receiver, uint256 maxPriceAllowed) external payable returns (uint256 mintAmount);
    function mint(address receiver, uint256 amount) external returns (uint256 mintAmount);
    function burnToEther(address receiver, uint256 burnAmount, uint256 minPriceAllowed) external returns (uint256 loanAmountPaid);
}

interface IKyberNetworkProxy {
    function swapEtherToToken(IERC20 token, uint minRate) external payable returns (uint);
    function getExpectedRate(IERC20 src, IERC20 dest, uint srcQty) external view returns (uint expectedRate, uint slippageRate);
}

contract Invest2Fulcrum_iDAI_NEW is Ownable, ReentrancyGuard {
    using SafeMath for uint;
 
    
    // state variables
    uint public balance;
    IKyberNetworkProxy public kyberNetworkProxyContract = IKyberNetworkProxy(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);
    IERC20 constant public ETH_TOKEN_ADDRESS = IERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    IERC20 public NEWDAI_TOKEN_ADDRESS = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        
    fulcrumInterface public fulcrumInterfaceContract = fulcrumInterface(0x493C57C4763932315A328269E1ADaD09653B9081);
    
    // events
    event UnitsReceivedANDSentToAddress(uint, address);

    
    // fx in relation to invest with ETH in fulcrum
    
     // - should we ever want to change the interface contract
    function set_fulcrumInterface(fulcrumInterface _fulcrumInterfaceContract) onlyOwner public {
        fulcrumInterfaceContract = _fulcrumInterfaceContract;
    }
    
    function set_kyberNetworkProxyContract(IKyberNetworkProxy _kyberNetworkProxyContract) onlyOwner public {
        kyberNetworkProxyContract = _kyberNetworkProxyContract;
    }
    
    // this function should be called should we ever want to change the NEWDAI_TOKEN_ADDRESS
    function set_NEWDAI_TOKEN_ADDRESS(IERC20 _NEWDAI_TOKEN_ADDRESS) onlyOwner public {
        NEWDAI_TOKEN_ADDRESS = _NEWDAI_TOKEN_ADDRESS;
    }
    
    // the investment fx
    function LetsInvest(address _towhomtoissue) public payable {
        require(_towhomtoissue != address(0));
        require(msg.value > 0);
        uint minConversionRate;
        (minConversionRate,) = kyberNetworkProxyContract.getExpectedRate(ETH_TOKEN_ADDRESS, NEWDAI_TOKEN_ADDRESS, msg.value);
        uint destAmount = kyberNetworkProxyContract.swapEtherToToken.value(msg.value)(NEWDAI_TOKEN_ADDRESS, minConversionRate);
        uint qty2approve = SafeMath.mul(destAmount, 3);
        require(NEWDAI_TOKEN_ADDRESS.approve(address(fulcrumInterfaceContract), qty2approve));
        uint UnitsIssued = fulcrumInterfaceContract.mint(_towhomtoissue, destAmount);
        emit UnitsReceivedANDSentToAddress(UnitsIssued, _towhomtoissue);
    }
    
    // fx, in case something goes wrong {hint! learnt from experience}
    function inCaseDAIgetsStuck() onlyOwner public {
        uint qty = NEWDAI_TOKEN_ADDRESS.balanceOf(address(this));
        NEWDAI_TOKEN_ADDRESS.transfer(_owner, qty);
    }
    

    // fx in relation to ETH held by the contract sent by the owner
    
    // - this function lets you deposit ETH into this wallet
    function depositETH() payable public onlyOwner returns (uint) {
        balance += msg.value;
    }
    
    // - fallback function let you / anyone send ETH to this wallet without the need to call any function
    function() external payable {
        if (msg.sender == _owner) {
            depositETH();
        } else {
            LetsInvest(msg.sender);
        }
    }
    
    // - to withdraw any ETH balance sitting in the contract
    function withdraw() onlyOwner public{
        _owner.transfer(address(this).balance);
    }
    
    
}