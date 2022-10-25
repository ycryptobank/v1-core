// SPDX-License-Identifier: apgl-3.0
pragma solidity ^0.8.12;

import "./utils/SafeERC20.sol";
import "./utils/Ownable.sol";
import "./YCBPairListContent.sol";

interface IYCBPairListContent {
    struct TradePair {
        address exchangePairToken;
        address targetPairToken;
        string pairName;
    }
    function getPairName() external view returns (string memory);
}

contract YCBTradeList {
    address[] tradePairList; // contain YCBPairListContent Contract
    address[] exchangePairList; // contain main pair token list 
    mapping (address => address[]) pairList; // contain main pair as key to target pair 
    address owner;
    constructor() {
        owner = msg.sender;
    }
    function getPairNameList() external view returns (string[] memory) {
        string[] memory _pairNameList;
        for (uint i=0; i<tradePairList.length; i++) {
            IYCBPairListContent _contentPairList = IYCBPairListContent(tradePairList[i]);
            _pairNameList[i] = _contentPairList.getPairName();
        }
        return _pairNameList;
    }
    function getPairListContent(address _selectedPairA, uint256 _selectedPairBIndex) external view returns (address) {
        address[] memory _selectedPairList = pairList[_selectedPairA];
        address _selectedPairListContent = _selectedPairList[_selectedPairBIndex];
        return _selectedPairListContent;
    }
    function registerNewPair(string memory _pairName, address _pairA, address _pairB) external onlyOwner {
        _registerNewPair(_pairName, _pairA, _pairB);
        exchangePairList.push(_pairA);
    }
    function registerNewPairForCustomer(string memory _pairName, uint256 _selectedPairA, address _pairB) external {
        address _pairA = exchangePairList[_selectedPairA];
        _registerNewPair(_pairName, _pairA, _pairB);
    }
    function _registerNewPair(string memory _pairName, address _pairA, address _pairB) private {
        address _newPair = address(new YCBPairListContent(_pairName, _pairA, _pairB, owner));
        pairList[_pairA].push(_pairB);
        tradePairList.push(_newPair);
    }
    modifier onlyOwner() {
		require((owner == msg.sender), "Ownable: Caller is not the assetOwner");
		_;
	}
}
