// SPDX-License-Identifier: apgl-3.0

pragma solidity ^0.8.17;

import "./utils/ReentrancyGuard.sol";
import "./interfaces/IYCBPassportPoolV1.sol";
import "./interfaces/IYCBPassport.sol";
import "./interfaces/IYCBActivationActivity.sol";
import "./interfaces/IYCBPassport.sol";

contract YCBPassportPool is ReentrancyGuard, IYCBPassportPoolV1 {

    uint256 public validationPrice = 49 ether;  // Price in Matic

    mapping(address => uint256) public validatedMembers;  // Mapping from address to expiry time for validation.

    address private owner;

    constructor() {
        owner = msg.sender;
    }

    function validate() external override payable {
        require(msg.value == validationPrice, "Incorrect payment amount");

        IYCBPassport passport = IYCBPassport(address(msg.sender));
        passport.validate(msg.value);
    }

    function getValidatedMember(address member) external view override returns(uint256) {
        return validatedMembers[member];
    }

    function setValidationPrice(uint256 newPrice) external onlyPoolOwner {
        validationPrice = newPrice;
    }

    function withdraw(address payable to, uint256 amount) external onlyPoolOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        to.transfer(amount);
    }

    modifier onlyPoolOwner() {
        require((owner == msg.sender), "Caller is not the pool Owner");
        _;
    }
}