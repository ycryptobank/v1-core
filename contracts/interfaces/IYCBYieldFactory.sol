// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.17;

/**
 * all writeable should be only owner and centralized
 */
interface IYCBYieldFactory {
    function createYieldCampaign(
        address _tokenYield,
        address _tokenBonus,
        uint _yieldRate, 
        uint _depositRate,
        uint _frozenPeriods
    ) external;
    function getActiveYields() external view returns (address[] memory _yields);
    function getInActiveYields() external view returns (address[] memory _yields);
    function startYield(
        address _yieldPath
    ) external;
    function completeYield(
        address _yieldPath,
        uint _amount
    ) external;
    function distributeYield(
        address _yieldPath,
        uint _amount,
        uint _tokenDecimals
    ) external;
}