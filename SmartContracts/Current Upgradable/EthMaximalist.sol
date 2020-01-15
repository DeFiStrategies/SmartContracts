
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


interface Invest2Fulcrum1xShortBTC {
    function LetsInvest2Fulcrum1xShortBTC(address _towhomtoissue) external payable;
}

interface Invest2Fulcrum {
    function LetsInvest2Fulcrum(address _towhomtoissue) external payable;
}


contract ETHMaximalist is Initializable {
    using SafeMath for uint;
    
    // state variables
    
    // - THESE MUST ALWAYS STAY IN THE SAME LAYOUT
    bool private stopped;
    address payable public owner;
    Invest2Fulcrum public Invest2FulcrumAddress;
    Invest2Fulcrum1xShortBTC public Invest2Fulcrum1xShortBTCContract;

    
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
        Invest2FulcrumAddress = Invest2Fulcrum(0xAB58BBF6B6ca1B064aa59113AeA204F554E8fBAe);
        Invest2Fulcrum1xShortBTCContract = Invest2Fulcrum1xShortBTC(0xa2C3e380E6c082A003819a2a69086748fe3D15Dd);
    }

    // this function should be called should we ever want to change the Invest2FulcrumAddress
    function set_Invest2FulcrumAddress(Invest2Fulcrum _Invest2FulcrumAddress) onlyOwner public {
        Invest2FulcrumAddress = _Invest2FulcrumAddress;
    }
    
    // this function should be called should we ever want to change the Invest2Fulcrum1xShortBTCContract address
    function set_Invest2Fulcrum1xShortBTCContract (Invest2Fulcrum1xShortBTC _Invest2Fulcrum1xShortBTCContract) onlyOwner public {
        Invest2Fulcrum1xShortBTCContract = _Invest2Fulcrum1xShortBTCContract;
    }
    

    
    // this function lets you deposit ETH into this wallet 
    function LetsInvest(address _towhomtoIssueAddress, uint _ShortBTCAllocation, uint _slippage) stopInEmergency payable public returns (bool) {
        require(_ShortBTCAllocation >= 0 || _ShortBTCAllocation <= 100, "wrong allocation");
        uint investAmt2ShortBTC = SafeMath.div(SafeMath.mul(msg.value,_ShortBTCAllocation), 100);
        uint investAmt2c2xLongETH = SafeMath.sub(msg.value, investAmt2ShortBTC);
        require (SafeMath.sub(msg.value,SafeMath.add(investAmt2ShortBTC, investAmt2c2xLongETH))==0, "Cannot split incoming ETH appropriately");
        Invest2Fulcrum1xShortBTCContract.LetsInvest2Fulcrum1xShortBTC.value(investAmt2ShortBTC)(_towhomtoIssueAddress);
        Invest2FulcrumAddress.LetsInvest2Fulcrum.value(investAmt2c2xLongETH)(_towhomtoIssueAddress);
        
    }
    function inCaseTokengetsStuck(IERC20 _TokenAddress) onlyOwner public {
        uint qty = _TokenAddress.balanceOf(address(this));
        _TokenAddress.transfer(owner, qty);
    }

    // - fallback function let you / anyone send ETH to this wallet without the need to call any function
    function() external payable {
        if (msg.sender != owner) {
            LetsInvest(msg.sender, 50, 5);}
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
