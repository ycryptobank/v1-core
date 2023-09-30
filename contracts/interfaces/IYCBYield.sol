// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.17;

interface IYCBYield {
    function depositYield(
        uint _amount
    ) external returns (uint _totalDeposit);
    function distributeBonusYield(
        uint[] memory _amountList
    ) external;
    function withdrawBonus() external;
    function withdrawFunds() external;
    function yieldCompleted() external;
    function yieldStarting() external;
    function getTokenYield() external view returns (address _tokenYield);
    function getTokenBonus() external view returns (address _tokenBonus);
    function emergencyTransfer(
        address _userPath,
        address _token,
        uint _amount
    ) external;
    function pauseYield(
        bool _isPaused
    ) external;
}