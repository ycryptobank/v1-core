// SPDX-License-Identifier: apgl-3.0

pragma solidity ^0.8.12;

import "./utils/ReentrancyGuard.sol";
import "./interfaces/IYCBPassport.sol";

contract YCBPassport is IYCBPassport, ReentrancyGuard {
    mapping(string => string) private addresses;
    string[] private chains;
    address private owner;
    address private passportPoolOwner;
    uint256 private expirationDate;
    address lastPassport;

    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == lastPassport, "Only the owner can call this function");
        _;
    }

    modifier onlyPassportPoolOwner() {
        require(msg.sender == passportPoolOwner, "Only the passport pool owner can call this function");
        _;
    }

    constructor(address _passportPoolOwner, address _lastPassport) {
        owner = msg.sender;
        passportPoolOwner = _passportPoolOwner;
        expirationDate = 0;
        lastPassport = _lastPassport;
    }

    function listAddress() external view override returns (string[] memory) {
        return chains;
    }

    function getAddresses(string memory chain) external view override returns (string memory) {
        return addresses[chain];
    }

    function setAddresses(string memory chain, string memory walletAddress) external override onlyOwner {
        addresses[chain] = walletAddress;
        chains.push(chain);
    }

    function isValid() external view override returns (bool) {
        return block.timestamp < expirationDate;
    }

    function validate(uint256 price) external payable override onlyPassportPoolOwner {
        require(msg.value >= price, "Insufficient validation fee");
        payable(passportPoolOwner).transfer(msg.value);
        expirationDate = block.timestamp + 365 days;
    }

    function migrate(IYCBPassport newPassport) external override onlyOwner {
        require(address(newPassport) != address(0), "Invalid new passport address");
        
        for (uint i = 0; i < chains.length; i++) {
            string memory chain = chains[i];
            string memory addr = addresses[chain];
            newPassport.setAddresses(chain, addr);
        }
    }
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}
