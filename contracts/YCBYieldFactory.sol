// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.17;
import "./interfaces/IYCBYieldFactory.sol";
import "./utils/SafeERC20.sol";
import "./utils/ReentrancyGuard.sol";

contract YCBYieldFactory is IYCBYieldFactory, ReentrancyGuard {
    function getActiveYields() external view returns (address[] memory yields) {

    }

    function startYield(
        address yieldPath
    ) external {

    }

    function distributeYield(
        address yieldPath,
        address token,
        uint amount
    ) external view returns (uint amountLeft) {

    }

    function createYield(
        address token,
        uint maxAmount
    ) external {

    }

    function checkProgressYield(
        address yieldPath
    ) external view returns (uint progress) {

    }
}