// SPDX-License-Identifier: apgl-3.0

pragma solidity ^0.8.17;

interface IYCBFlexibleActivity {
    function checkDuration() external returns (uint);
    function checkActiveStatus() external returns (bool);
}