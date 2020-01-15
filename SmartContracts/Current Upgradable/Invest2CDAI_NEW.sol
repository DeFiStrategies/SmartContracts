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


interface IKyberInterface {
    function swapTokentoToken(IERC20 _srcTokenAddressIERC20, IERC20 _dstTokenAddress, uint _slippageValue, address _toWhomToIssue) external payable returns (uint);
}


interface Compound {
    function approve (address spender, uint256 amount ) external returns ( bool );
    function mint ( uint256 mintAmount ) external returns ( uint256 );
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint _value) external returns (bool success);
}


contract Invest2cDAI_NEW is Initializable {
    using SafeMath for uint;
    
    // state variables
    
    // - THESE MUST ALWAYS STAY IN THE SAME LAYOUT
    bool private stopped = false;
    address payable public owner;
    IKyberInterface public KyberInterfaceAddress;
    IERC20 public NEWDAI_TOKEN_ADDRESS;
    Compound public COMPOUND_TOKEN_ADDRESS;
    
    // events
    event UnitsReceivedANDSentToAddress(uint, address);

    // circuit breaker modifiers
    modifier stopInEmergency {if (!stopped) _;}
    modifier onlyInEmergency {if (stopped) _;}
    modifier onlyOwner() {
        require(isOwner(), "you are not authorised to call this function");
        _;
    }

    function initialize(address _KyberInterfaceAddress) initializer public {
        owner = msg.sender;
        KyberInterfaceAddress = IKyberInterface(_KyberInterfaceAddress);
        NEWDAI_TOKEN_ADDRESS = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        COMPOUND_TOKEN_ADDRESS = Compound(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
    }

    // this function should be called should we ever want to change the KyberInterfaceAddress address
    function set_KyberInterfaceAddress(address _new__KyberInterfaceAddress) public onlyOwner {
        KyberInterfaceAddress = IKyberInterface(_new__KyberInterfaceAddress);
    }

    // this function should be called should we ever want to change the NEWDAI_TOKEN_ADDRESS
    function set_NEWDAI_TOKEN_ADDRESS(IERC20 _NEWDAI_TOKEN_ADDRESS) onlyOwner public {
        NEWDAI_TOKEN_ADDRESS = _NEWDAI_TOKEN_ADDRESS;
    }
    // this function should be called should we ever want to change the COMPOUND_TOKEN_ADDRESS 
    function set_COMPOUND_TOKEN_ADDRESS(Compound _COMPOUND_TOKEN_ADDRESS) onlyOwner public {
        COMPOUND_TOKEN_ADDRESS = _COMPOUND_TOKEN_ADDRESS;
    }
    
    
    // 
    function LetsInvest(address _toWhomToIssue, uint _slippage) public stopInEmergency payable {
        KyberInterfaceAddress.swapTokentoToken.value(msg.value)(IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),IERC20(NEWDAI_TOKEN_ADDRESS),_slippage,address(this));
        uint TokensReceived = NEWDAI_TOKEN_ADDRESS.balanceOf(address(this));
        require(NEWDAI_TOKEN_ADDRESS.approve(address(COMPOUND_TOKEN_ADDRESS), TokensReceived), "Some issue in approving in DAI contrat");
        COMPOUND_TOKEN_ADDRESS.mint(TokensReceived); 
        uint cDAI2transfer = COMPOUND_TOKEN_ADDRESS.balanceOf(address(this));
        require(COMPOUND_TOKEN_ADDRESS.transfer(_toWhomToIssue, cDAI2transfer), "Some issue in transferring cDAI");
        require(NEWDAI_TOKEN_ADDRESS.approve(address(COMPOUND_TOKEN_ADDRESS), 0), "Resettig approval value to 0");
        emit UnitsReceivedANDSentToAddress(TokensReceived, _toWhomToIssue);
    }

    // fx, in case something goes wrong
    function inCaseTokengetsStuck(IERC20 _TokenAddress) onlyOwner public {
        uint qty = _TokenAddress.balanceOf(address(this));
        _TokenAddress.transfer(owner, qty);
    }
    
    // - fallback function let you / anyone send ETH to this wallet without the need to call any function
    function() external payable {
        if (msg.sender != owner) {
            LetsInvest(msg.sender, 5);}
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