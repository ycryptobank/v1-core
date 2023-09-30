// SPDX-License-Identifier: apgl-3.0

pragma solidity ^0.8.17;

import "./utils/ReentrancyGuard.sol";
import "./interfaces/IYCBPassportPoolV1.sol";
import "./interfaces/IYCBPassport.sol";

contract YCBPassportPool is ReentrancyGuard, IYCBPassportPoolV1 {
    uint256 public validationPrice = 49 ether; // Price in Matic

    mapping(address => uint256) public validatedMembers;

    address private owner;

    constructor() {
        owner = msg.sender;
    }

    function validate() external payable override {
        require(msg.value >= validationPrice, "Incorrect payment amount");
        validatedMembers[msg.sender] = block.timestamp + 365 days;
    }

    function revalidate(address newPassport, address oldPassport) external override onlyPoolOwner {
        validatedMembers[newPassport] = validatedMembers[oldPassport];
    }

    function isValid() external view override returns (bool) {
        return validatedMembers[msg.sender] >= block.timestamp;
    }

    // To check isValid status of validated Member
    function getValidatedMember(address member)
        external
        view
        override
        returns (bool)
    {
        return validatedMembers[member] >= block.timestamp;
    }

    function getValidatedMemberDate(address member) external view override returns(uint256) {
        return validatedMembers[member];
    }

    function setValidationPrice(uint256 newPrice) external onlyPoolOwner {
        validationPrice = newPrice;
    }

    function withdraw(address payable to, uint256 amount)
        external
        onlyPoolOwner
    {
        require(address(this).balance >= amount, "Insufficient balance");
        to.transfer(amount);
    }

    modifier onlyPoolOwner() {
        require((owner == msg.sender), "Caller is not the pool Owner");
        _;
    }
}
