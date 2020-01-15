// Copyright (C) 2019, 2020 dipeshsukhani, nodarjonashi, toshsharma, suhailg

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// Visit <https://www.gnu.org/licenses/>for a copy of the GNU Affero General Public License

/**
 * WARNING: This is an upgradable contract. Be careful not to disrupt
 * the existing storage layout when making upgrades to the contract. In particular,
 * existing fields should not be removed and should not have their types changed.
 * The order of field declarations must not be changed, and new fields must be added
 * below all existing declarations.
 *
 * The base contracts and the order in which they are declared must not be changed.
 * New fields must not be added to base contracts (unless the base contract has
 * reserved placeholder fields for this purpose).
 *
 * See https://docs.zeppelinos.org/docs/writing_contracts.html for more info.
*/

pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

///@author DeFiZap
///@notice this contract implements one click conversion from ETH to unipool liquidity tokens (cDAI)

interface IuniswapFactory {
    function getExchange(address token) external view returns (address exchange);
}


interface IuniswapExchange {
    function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought);
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256  tokens_bought);
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);
}

interface IKyberInterface {
    function swapTokentoToken(IERC20 _srcTokenAddressIERC20, IERC20 _dstTokenAddress, uint _slippageValue, address _toWhomToIssue) external payable returns (uint);
}

interface Compound {
    function approve ( address spender, uint256 amount ) external returns ( bool );
    function mint ( uint256 mintAmount ) external returns ( uint256 );
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint _value) external returns (bool success);
}


contract UniSwap_ETH_CDAIZap is Initializable {
    using SafeMath for uint;
    // state variables
    
    // - THESE MUST ALWAYS STAY IN THE SAME LAYOUT
    bool private stopped;
    address payable public owner;
    IuniswapFactory public UniSwapFactoryAddress;
    IKyberInterface public KyberInterfaceAddresss;
    IERC20 public NEWDAI_TOKEN_ADDRESS;
    Compound public COMPOUND_TOKEN_ADDRESS;
    

    // events
    event ERC20TokenHoldingsOnConversionDaiChai(uint);
    event ERC20TokenHoldingsOnConversionEthDai(uint);
    event LiquidityTokens(uint);
     
    // circuit breaker modifiers
    modifier stopInEmergency {if (!stopped) _;}
    modifier onlyInEmergency {if (stopped) _;}
    modifier onlyOwner() {
        require(isOwner(), "you are not authorised to call this function");
        _;
    }
    
    
    function initialize() initializer public {
        stopped = false;
        owner = msg.sender;
        UniSwapFactoryAddress = IuniswapFactory(0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95);
        NEWDAI_TOKEN_ADDRESS = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        COMPOUND_TOKEN_ADDRESS = Compound(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
        KyberInterfaceAddresss = IKyberInterface(0x16183BE9f0c145fc6c24E1780211F51767382135);
    }

    
    function set_new_UniSwapFactoryAddress(address _new_UniSwapFactoryAddress) public onlyOwner {
        UniSwapFactoryAddress = IuniswapFactory(_new_UniSwapFactoryAddress);
        
    }

    function set_new_DAI_TOKEN_ADDRESS(address _new_DAI_TOKEN_ADDRESS) public onlyOwner {
        NEWDAI_TOKEN_ADDRESS = IERC20(_new_DAI_TOKEN_ADDRESS);
        
    }

    function set_new_cDAI_TokenContractAddress(address _new_cDAI_TokenContractAddress) public onlyOwner {
        COMPOUND_TOKEN_ADDRESS = Compound(address(_new_cDAI_TokenContractAddress));
        
    }

    function set_KyberInterfaceAddresss(IKyberInterface _new_KyberInterfaceAddresss) public onlyOwner {
        KyberInterfaceAddresss = _new_KyberInterfaceAddresss;
    }

    
    
    function LetsInvest(address _src, address _towhomtoissue, uint _MaxslippageValue) public payable stopInEmergency returns (uint) {
        IERC20 ERC20TokenAddress = IERC20(address(COMPOUND_TOKEN_ADDRESS));
        IuniswapExchange UniSwapExchangeContractAddress = IuniswapExchange(UniSwapFactoryAddress.getExchange(address(COMPOUND_TOKEN_ADDRESS)));

        // determining the portion of the incoming ETH to be converted to the ERC20 Token
        uint conversionPortion = SafeMath.div(SafeMath.mul(msg.value, 505), 1000);
        uint non_conversionPortion = SafeMath.sub(msg.value,conversionPortion);

        KyberInterfaceAddresss.swapTokentoToken.value(conversionPortion)(IERC20(_src), NEWDAI_TOKEN_ADDRESS, _MaxslippageValue, address(this));
        uint tokenBalance = NEWDAI_TOKEN_ADDRESS.balanceOf(address(this));
        // conversion of DAI to cDAI
        uint qty2approve = SafeMath.mul(tokenBalance, 3);
        require(NEWDAI_TOKEN_ADDRESS.approve(address(ERC20TokenAddress), qty2approve));
        COMPOUND_TOKEN_ADDRESS.mint(tokenBalance);
        uint ERC20TokenHoldings = ERC20TokenAddress.balanceOf(address(this));
        require (ERC20TokenHoldings > 0, "the conversion did not happen as planned");
        emit ERC20TokenHoldingsOnConversionDaiChai(ERC20TokenHoldings);
        NEWDAI_TOKEN_ADDRESS.approve(address(ERC20TokenAddress), 0);
        ERC20TokenAddress.approve(address(UniSwapExchangeContractAddress),ERC20TokenHoldings);

        // adding Liquidity
        uint max_tokens_ans = getMaxTokens(address(UniSwapExchangeContractAddress), ERC20TokenAddress, non_conversionPortion);
        UniSwapExchangeContractAddress.addLiquidity.value(non_conversionPortion)(1,max_tokens_ans,SafeMath.add(now,1800));
        ERC20TokenAddress.approve(address(UniSwapExchangeContractAddress),0);

        // transferring Liquidity
        uint LiquityTokenHoldings = UniSwapExchangeContractAddress.balanceOf(address(this));
        emit LiquidityTokens(LiquityTokenHoldings);
        UniSwapExchangeContractAddress.transfer(_towhomtoissue, LiquityTokenHoldings);
        ERC20TokenHoldings = ERC20TokenAddress.balanceOf(address(this));
        ERC20TokenAddress.transfer(_towhomtoissue, ERC20TokenHoldings);
        return LiquityTokenHoldings;
    }

    function getMaxTokens(address _UniSwapExchangeContractAddress, IERC20 _ERC20TokenAddress, uint _value) internal view returns (uint) {
        uint contractBalance = address(_UniSwapExchangeContractAddress).balance;
        uint eth_reserve = SafeMath.sub(contractBalance, _value);
        uint token_reserve = _ERC20TokenAddress.balanceOf(_UniSwapExchangeContractAddress);
        uint token_amount = SafeMath.div(SafeMath.mul(_value,token_reserve),eth_reserve) + 1;
        return token_amount;
    }
    

    // incase of half-way error
    function inCaseTokengetsStuck(IERC20 _TokenAddress) onlyOwner public {
        uint qty = _TokenAddress.balanceOf(address(this));
        _TokenAddress.transfer(owner, qty);
    }
    
    // - fallback function let you / anyone send ETH to this wallet without the need to call any function
    function() external payable {
        if (msg.sender != owner) {
            LetsInvest(address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE), msg.sender, 5);}
    }
    
// - to Pause the contract
    function toggleContractActive() onlyOwner public {
        stopped = !stopped;
    }
    // - to withdraw any ETH balance sitting in the contract
    function withdraw() onlyOwner public{
        owner.transfer(address(this).balance);
    }
    // - to kill the contract
    function destruct() public onlyOwner {
        selfdestruct(owner);
    }
    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address payable newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = newOwner;
    }
    
}
