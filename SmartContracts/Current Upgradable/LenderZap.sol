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

// interfaces 
interface Invest2cDAI {
    function LetsInvest(address _toWhomToIssue, uint _slippage) external payable;
}

interface Invest2Fulcrum {
    function LetsInvest2Fulcrum(address _towhomtoissue) external payable;
}


// through this contract we are putting a user specified allocation to cDAI and the balance to 2xLongETH
contract LenderZap_NEWDAI is Initializable {
    using SafeMath for uint;
    
    // state variables
    
    // - THESE MUST ALWAYS STAY IN THE SAME LAYOUT
    bool private stopped = false;
    address payable public owner;
    Invest2cDAI public Invest2cDAIAddress;
    Invest2Fulcrum public Invest2FulcrumAddress;
    
    // circuit breaker modifiers
    modifier stopInEmergency {if (!stopped) _;}
    modifier onlyInEmergency {if (stopped) _;}
    modifier onlyOwner() {
        require(isOwner(), "you are not authorised to call this function");
        _;
    }


    
    function initialize(address _Invest2cDAIAddress) initializer public {
        owner = msg.sender;
        Invest2cDAIAddress = Invest2cDAI(_Invest2cDAIAddress);
        Invest2FulcrumAddress = Invest2Fulcrum(0xAB58BBF6B6ca1B064aa59113AeA204F554E8fBAe);
    }

    // this function should be called should we ever want to change the Invest2cDAIAddress
    function set_Invest2cDAIAddress(Invest2cDAI _Invest2cDAIAddress) onlyOwner public {
        Invest2cDAIAddress = _Invest2cDAIAddress;
    }

    // this function should be called should we ever want to change the Invest2FulcrumAddress
    function set_Invest2FulcrumAddress(Invest2Fulcrum _Invest2FulcrumAddress) onlyOwner public {
        Invest2FulcrumAddress = _Invest2FulcrumAddress;
    }

        
    // this function lets you deposit ETH into this wallet 
    function LetsInvest(address _towhomtoIssueAddress, uint _cDAIAllocation, uint _slippage) stopInEmergency payable public returns (bool) {
        require(_cDAIAllocation >= 0 || _cDAIAllocation <= 100, "wrong allocation");
        uint investAmt2cDAI = SafeMath.div(SafeMath.mul(msg.value,_cDAIAllocation), 100);
        uint investAmt2cFulcrum = SafeMath.sub(msg.value, investAmt2cDAI);
        require (SafeMath.sub(msg.value,SafeMath.add(investAmt2cDAI, investAmt2cFulcrum)) == 0, "Cannot split incoming ETH appropriately");
        Invest2cDAIAddress.LetsInvest.value(investAmt2cDAI)(_towhomtoIssueAddress, _slippage);
        Invest2FulcrumAddress.LetsInvest2Fulcrum.value(investAmt2cFulcrum)(_towhomtoIssueAddress);
        return true;
    }

    
    function inCaseTokengetsStuck(IERC20 _TokenAddress) onlyOwner public {
        uint qty = _TokenAddress.balanceOf(address(this));
        _TokenAddress.transfer(owner, qty);
    }
    
    // - fallback function let you / anyone send ETH to this wallet without the need to call any function
    function() external payable {
        if (msg.sender != owner) {
            LetsInvest(msg.sender, 90, 5);}
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
