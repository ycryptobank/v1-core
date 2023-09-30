// SPDX-License-Identifier: apgl-3.0

pragma solidity ^0.8.17;

import "./interfaces/IYCBPassport.sol";
import "./interfaces/IYCBFlexibleActivity.sol";
import "./interfaces/IYCBActivationActivity.sol";

contract YCBYieldFlexible is IYCBFlexibleActivity, IYCBActivationActivity {

    address owner;
    address poolOwner;
    string yieldName;

    bool isExpired;
    uint public periodYield;
    uint public totalPassports;

    mapping (address => bool) activeStacker;

    constructor(
        string memory _name,
        uint _periodYield, 
        address _poolOwner
    ) {
        owner = msg.sender;
        yieldName = _name;
        periodYield = _periodYield;
        poolOwner = _poolOwner;
        totalPassports = 0;
    }

    function checkDuration() external view returns (uint) {
        return periodYield + block.timestamp;
    }

    function checkActiveStatus() external view returns (bool) {
        return activeStacker[msg.sender];
    }

    function activate(address passport) external onlyPassportPoolOwner {
        
    }

    function deactivate(address passport) external onlyPassportPoolOwner {
        // put back user money to passport
        activeStacker[passport] = false;
    }

    modifier onlyYieldOwner() {
        require((owner == msg.sender), "Caller is not Yield Owner");
        _;
    }

    modifier onlyPassportPoolOwner() {
        require((poolOwner == msg.sender), "Caller is not the Official Pool");
        _;
    }
}

/**
 * 
 * uint256 totalAllStackedCustomer = 10000;
uint256 totalStackedSingleCustomer = 1000;
uint256 totalSupply = 1000000;
uint256 distributedToken = 500;

uint256 percentageAllStackedCustomer = totalAllStackedCustomer * 100 / totalSupply;
uint256 percentageStackedSingleCustomer = totalStackedSingleCustomer * 100 / totalSupply;

uint256 distributedTokenForSingleCustomer = distributedToken * percentageStackedSingleCustomer / percentageAllStackedCustomer;

 * 
 * 
 */