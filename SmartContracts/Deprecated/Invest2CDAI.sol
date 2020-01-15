pragma solidity ^0.5.0;

import "./Ownable.sol";
import "./SafeMath.sol";

interface IKyberNetworkProxy {
    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) external view returns (uint expectedRate, uint slippageRate);
    function tradeWithHint(ERC20 src, uint srcAmount, ERC20 dest, address destAddress, uint maxDestAmount, uint minConversionRate, address walletId, bytes calldata hint) external payable returns(uint);
    function swapEtherToToken(ERC20 token, uint minRate) external payable returns (uint);
}

interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


interface Compound {
    function approve ( address spender, uint256 amount ) external returns ( bool );
    function mint ( uint256 mintAmount ) external returns ( uint256 );
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint _value) external returns (bool success);
}


contract Invest2cDAI is Ownable {
    using SafeMath for uint;
    
    // state variables
    // - setting up Imp Contract Addresses
    IKyberNetworkProxy public kyberNetworkProxyContract = IKyberNetworkProxy(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);
    ERC20 constant public ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    ERC20 public DAI_TOKEN_ADDRESS = ERC20(0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359);
    Compound public COMPOUND_TOKEN_ADDRESS = Compound(0xF5DCe57282A584D2746FaF1593d3121Fcac444dC);
    
    // - variable for tracking the ETH balance of this contract
    uint public balance;
    
    // events
    event AmountInvested(string successmessage, uint numberOfTokensIssued);

    // this function should be called should we ever want to change the kyberNetworkProxyContract address
    function set_kyberNetworkProxyContract(IKyberNetworkProxy _kyberNetworkProxyContract) onlyOwner public {
        kyberNetworkProxyContract = _kyberNetworkProxyContract;
    }
    
    // this function should be called should we ever want to change the DAI_TOKEN_ADDRESS
    function set_DAI_TOKEN_ADDRESS(ERC20 _DAI_TOKEN_ADDRESS) onlyOwner public {
        DAI_TOKEN_ADDRESS = _DAI_TOKEN_ADDRESS;
    }
    // this function should be called should we ever want to change the COMPOUND_TOKEN_ADDRESS 
    function set_COMPOUND_TOKEN_ADDRESS(Compound _COMPOUND_TOKEN_ADDRESS) onlyOwner public {
        COMPOUND_TOKEN_ADDRESS = _COMPOUND_TOKEN_ADDRESS;
    }
    
    
    // 
    function letsGetSome_cDAI(address _towhomtoissue) public payable {
        uint minConversionRate;
        (minConversionRate,) = kyberNetworkProxyContract.getExpectedRate(ETH_TOKEN_ADDRESS, DAI_TOKEN_ADDRESS, msg.value);
        uint destAmount = kyberNetworkProxyContract.swapEtherToToken.value(msg.value)(DAI_TOKEN_ADDRESS, minConversionRate);
        uint qty2approve = SafeMath.mul(destAmount, 3);
        require(DAI_TOKEN_ADDRESS.approve(address(COMPOUND_TOKEN_ADDRESS), qty2approve));
        COMPOUND_TOKEN_ADDRESS.mint(destAmount); 
        uint cDAI2transfer = COMPOUND_TOKEN_ADDRESS.balanceOf(address(this));
        require(COMPOUND_TOKEN_ADDRESS.transfer(_towhomtoissue, cDAI2transfer));
        emit AmountInvested("Done! the number of cDAI issued are: ", cDAI2transfer);
    }
    
    // fx, in case something goes wrong {hint! learnt from experience}
    function inCaseDAIgetsStuck() onlyOwner public {
        uint qty = DAI_TOKEN_ADDRESS.balanceOf(address(this));
        DAI_TOKEN_ADDRESS.transfer(owner, qty);
    }
    
    function inCaseC_DAIgetsStuck() onlyOwner public {
        uint CDAI_qty = COMPOUND_TOKEN_ADDRESS.balanceOf(address(this));
        COMPOUND_TOKEN_ADDRESS.transfer(owner, CDAI_qty);
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
            letsGetSome_cDAI(msg.sender);
        }
    }
    
    // - to withdraw any ETH balance sitting in the contract
    function withdraw() onlyOwner public{
        owner.transfer(address(this).balance);
    }
 
}