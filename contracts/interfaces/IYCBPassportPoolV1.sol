// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.17;

interface IYCBPassportPoolV1 {
    function validate() external payable;
    function getValidatedMember(address member) external view returns(uint256);
}