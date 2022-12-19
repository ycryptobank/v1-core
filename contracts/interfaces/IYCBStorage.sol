// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.17;

/**
 * all should expected onlyOwner
 */
interface IYCBStorage {
    function lockToYield(
        address _yieldPath,
        address _token,
        uint _amount,
        string memory _password
    ) external returns (uint _amountLocked);
    function withdrawFunds(
        string memory _password
    ) external;
    function withdrawBonus(
        string memory _password
    ) external;
    function listDepositToken() external view returns (address[] memory tokens);
    function isActiveStorage() external view returns (bool _isActiveStorage);
}