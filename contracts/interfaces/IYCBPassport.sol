// SPDX-License-Identifier: apgl-3.0

pragma solidity ^0.8.17;

interface IYCBPassport {
    function listAddress() external view returns (string[] memory);
    function getAddresses(string memory chain) external view returns (string memory);
    function setAddresses(string memory chain, string memory walletAddress) external;
    function isValid() external view returns (bool);
    function validate(uint256 price) external payable;
    function migrate(IYCBPassport newPassport) external;
}