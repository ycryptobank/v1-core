// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.17;
import "./interfaces/IYCBStorageFactory.sol";
import "./YCBStorage.sol";
import "./interfaces/IYCBStorage.sol";

contract YCBStorageFactory is IYCBStorageFactory {

    mapping (address => address[]) storageList;

    function createStorage(
        string memory _password,
        address _yieldAddress
    ) external returns (address _generatedStorage) {
        // address storageAddress = address(new YCBStorage(_password, _yieldAddress));
        // storageList[msg.sender].push(storageAddress);
        // _generatedStorage = storageAddress;
    }

    function getStorageList(
        bool isActive
    ) external view returns (address[] memory) {
        address[] memory _filteredList = new address[](storageList[msg.sender].length);
        uint _index = 0;
        for (uint i = 0; i < _filteredList.length; i++) {
            IYCBStorage _storage = IYCBStorage(storageList[msg.sender][i]);
            if (_storage.isActiveStorage() == isActive) {
                _filteredList[_index] = address(_storage);
                _index = _index + 1;
            }
        }
        return _filteredList;
    }
}