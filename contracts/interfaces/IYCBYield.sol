// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.17;

interface IYCBYield {
    function depositYield(
        uint _amount
    ) external returns (uint _totalDeposit);
    function distributeBonusYield(
        uint _amount,
        uint _tokenDecimals
    ) external;
    function withdrawBonus() external;
    function withdrawFunds() external;
    function yieldCompleted() external;
    function yieldStarting() external;
    function emergencyTransfer(
        address _userPath,
        address _token,
        uint _amount
    ) external;
}