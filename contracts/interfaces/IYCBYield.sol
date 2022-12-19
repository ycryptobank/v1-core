// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.17;

interface IYCBYield {
    /**
     * triggered by Factory YIeld
     */
    function distributeYield(
        uint _amount
    ) external returns (uint _amountLeft);
    /**
     * triggered by IYCBStorage owner
     */
    function depositYield(
        address _userPath,
        address _token,
        uint _amount
    ) external returns (uint _totalDeposit);
    /**
     * trigger by owner
     */
    function emergencyTransfer(
        address _storagePath,
        address _token,
        uint _amount
    ) external;
}