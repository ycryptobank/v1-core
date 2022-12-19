// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.17;

interface IYCBStorageFactory {
    function createStorage(
        string memory _password,
        address _yieldAddress
    ) external returns(address _generatedStorage);
    function getStorageList(
        bool isActive
    ) external view returns (address[] memory);
}