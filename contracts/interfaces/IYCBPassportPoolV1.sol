// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.17;

interface IYCBPassportPoolV1 {
    function isValid() external view returns (bool);
    function validate() external payable;
    function revalidate(address newPassport, address oldPassport) external;
    function getValidatedMember(address member) external view returns(bool);
    function getValidatedMemberDate(address member) external view returns(uint256);
}