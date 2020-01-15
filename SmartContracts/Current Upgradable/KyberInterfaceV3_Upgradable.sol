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


interface IKyberNetworkProxy {
    function getExpectedRate(IERC20 src, IERC20 dest, uint srcQty) external view returns (uint expectedRate, uint slippageRate);
    function trade(IERC20 src, uint srcAmount, IERC20 dest, address destAddress, uint maxDestAmount, uint minConversionRate, address walletId) external payable returns (uint);
}



contract KyberInterace is Initializable {
    using SafeMath for uint;
    
    // state variables
    // - THESE MUST ALWAYS STAY IN THE SAME LAYOUT
    bool private stopped = false;
    address payable public owner;
    IKyberNetworkProxy public kyberNetworkProxyContract;
    address private _wallet;
        
    // events
    event TokensReceived(uint, uint);
    
    // circuit breaker modifiers
    modifier stopInEmergency {if (!stopped) _;}
    modifier onlyInEmergency {if (stopped) _;}
    modifier onlyOwner() {
        require(isOwner(), "you are not authorised to call this function");
        _;
    }

    function initialize(address _walletAddress) initializer public {
        _wallet = _walletAddress;
        owner = msg.sender;
        kyberNetworkProxyContract = IKyberNetworkProxy(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);
    }

    // for setting the wallet address which has been registered with Kyber
    function set_wallet (address _new_wallet) public onlyOwner {
        _wallet = _new_wallet;
    }

    // for getting the wallet address which has been registered with Kyber
    function get_wallet() public view onlyOwner returns (address) {
        return _wallet;
    }
    
    // this function should be called should we ever want to change the kyberNetworkProxyContract address
    function set_kyberNetworkProxyContract(IKyberNetworkProxy _kyberNetworkProxyContract) onlyOwner public {
        kyberNetworkProxyContract = _kyberNetworkProxyContract;
    }
    
     
    function swapTokentoToken(IERC20 _srcTokenAddressIERC20, IERC20 _dstTokenAddress, uint _slippageValue, address _toWhomToIssue) public payable stopInEmergency returns (uint) {
        require(_wallet != address(0), "internal error, contact owner");
        require(_slippageValue < 100 && _slippageValue >= 0, "slippage value absurd");
        uint minConversionRate;
        uint slippageRate;
        (minConversionRate,slippageRate) = kyberNetworkProxyContract.getExpectedRate(_srcTokenAddressIERC20, _dstTokenAddress, msg.value);
        uint realisedValue = SafeMath.sub(100,_slippageValue);
        uint destAmount = kyberNetworkProxyContract.trade.value(msg.value)(_srcTokenAddressIERC20, msg.value, _dstTokenAddress, _toWhomToIssue, 2**255, (SafeMath.div(SafeMath.mul(minConversionRate,realisedValue),100)), _wallet);
        return destAmount;
    }
    
    // fx, in case something goes wrong {hint! learnt from experience}
    function inCaseTokengetsStuck(IERC20 _TokenAddress) onlyOwner public {
        uint qty = _TokenAddress.balanceOf(address(this));
        _TokenAddress.transfer(owner, qty);
    }
    
    
    // - fallback function let you / anyone send ETH to this wallet without the need to call any function
    function() external payable {
        revert("not allowed to send ETH to this address");
    }
    

    // - to Pause the contract
    function toggleContractActive() onlyOwner public {
        stopped = !stopped;
    }
    
    // - to withdraw any ETH balance sitting in the contract
    function withdraw() onlyOwner public{
        owner.transfer(address(this).balance);
    }
    
    function destruct() onlyOwner public{
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
    
    // function _check() pure public returns(uint) {
    //     return 44;
    // }
 
}
