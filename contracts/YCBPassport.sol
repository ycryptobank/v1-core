// SPDX-License-Identifier: apgl-3.0

pragma solidity ^0.8.17;

import "./YCBYieldFlexible.sol";
import "./utils/ReentrancyGuard.sol";

interface IYCBPassport {
    function paySubscription() external;
    function getRemainingCredits() external view returns (uint);
    function joinYield() external;
}

contract YCBPassport is IYCBPassport, ReentrancyGuard {

    bool isActive;
    address poolOwner;
    uint credits;
    uint expiration;

    address[] public activeYieldList;

    address passportOwner;

    constructor(
        address _passportOwner
    ) {
        poolOwner = msg.sender;
        isActive = false;
        credits = 0;
        passportOwner = _passportOwner;
    }

    function joinYield() external nonReentrant onlyPoolOwner checkExpiration {
        activeYieldList.push(msg.sender);
    }
    
    function paySubscription() external nonReentrant checkExpiration {
        if (isActive) {
            credits += 4 weeks;
        } else {
            credits += block.timestamp + 4 weeks;
        }
        isActive = true;
    }

    function getRemainingCredits() external view returns (uint) {
        return credits;
    }

    modifier onlyPoolOwner() {
        require((poolOwner == msg.sender), "Caller is not Pool Owner");
        _;
    }

    modifier onlyPassportOwner() {
        require((passportOwner == msg.sender), "Caller is not the Passport Owner");
        _;
    }

    modifier checkExpiration() {
        bool _checkExpiration = credits > block.timestamp;
        isActive = _checkExpiration;
        require((_checkExpiration), "Error: Need Renew Passport");
        _;
    }
}

contract YCBPassportPool is ReentrancyGuard {

    address owner;

    mapping ( address => address ) passportList;

    constructor() {
        owner = msg.sender;
    }

    function createPassport() external {
        address _newPassport = address(new YCBPassport(msg.sender));
        passportList[msg.sender] = _newPassport;
    }

    function activatePassport() external {
        IYCBPassport _passport = IYCBPassport(passportList[msg.sender]);
        _passport.paySubscription();
        passportList[msg.sender] = address(_passport);
    }

    function getMyPassport() external view returns (IYCBPassport) {
        IYCBPassport _passport = IYCBPassport(passportList[msg.sender]);
        return _passport;
    }

    function joinYield(address yieldFlexible) external nonReentrant {
        IYCBYieldActivation _yieldFlexible = IYCBYieldActivation(yieldFlexible);
        _yieldFlexible.activate(passportList[msg.sender]);
    }

    modifier onlyPoolOwner() {
        require((owner == msg.sender), "Caller is not the pool Owner");
        _;
    }
}