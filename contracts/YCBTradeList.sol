// SPDX-License-Identifier: apgl-3.0
pragma solidity ^0.8.12;

import "./CurciferAsset.sol";
import "./utils/SafeERC20.sol";
import "./utils/Ownable.sol";
import "./YCBPairListContent.sol";

interface YCBPairListContentInterface {
    struct TradePair {
        address exchangePairToken;
        address targetPairToken;
        string pairName;
    }
    function getPairName() external view returns (string memory);
}

contract YCBTradeList {
    address[] tradePairList;
    function getPairNameList() external view returns (string[] memory) {
        string[] memory _pairNameList;
        for (uint i=0; i<tradePairList.length; i++) {
            YCBPairListContentInterface _contentPairList = YCBPairListContentInterface(tradePairList[i]);
            _pairNameList[i] = _contentPairList.getPairName();
        }
        return _pairNameList;
    }
    function selectPairList(address selectedContract) external pure returns (YCBPairListContentInterface) {
        YCBPairListContentInterface _pairlListContentContract = YCBPairListContentInterface(selectedContract);
        return _pairlListContentContract;
    }
    function registerNewPair(string memory _pairName, address _pairA, address _pairB) external {
        address _newPair = address(new YCBPairListContent(_pairName, _pairA, _pairB));
        tradePairList.push(_newPair);
    }
}
