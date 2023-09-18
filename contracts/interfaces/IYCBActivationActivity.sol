// SPDX-License-Identifier: apgl-3.0

pragma solidity ^0.8.17;

interface IYCBActivationActivity {
    function activate(address passport) external;
    function deactivate(address passport) external;
}