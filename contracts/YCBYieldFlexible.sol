// SPDX-License-Identifier: apgl-3.0

pragma solidity ^0.8.17;

import "./YCBPassport.sol";

interface IYCBYieldFlexible {
    function checkDuration() external returns (bool);
}

interface IYCBYieldActivation{
    function activate(address passport) external;
}

contract YCBYieldFlexible is IYCBYieldFlexible, IYCBYieldActivation {

    address owner;
    address poolOwner;
    string yieldName;

    bool isExpired;
    uint public periodYield;
    uint public totalPassports;

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

    function checkDuration() external view returns (bool) {
        return isExpired;
    }

    function activate(address passport) external onlyPassportPoolOwner {
        IYCBPassport _passport = IYCBPassport(passport);
        _passport.joinYield();
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