// SPDX-License-Identifier: agpl-3.0


pragma solidity ^0.8.12;

import "./CurciferAsset.sol";
import "./utils/SafeERC20.sol";
import "./utils/Ownable.sol";

error UnknownAssetOwner();

contract CurciferAssetList is Ownable {
	using SafeERC20 for IERC20;

	event AssetOwnerError(
		uint errorStatus
	);

	struct BuyerInfo {
		uint selectedOrderIndex;
		bool isOnGoing;
	}

	mapping(address => address) public assetList;
	mapping(address => BuyerInfo) public buyerList;

	address[] private providerList;
	address[] private feeTokenList;
	uint256[] private feePriceList;

	function createNewOrder(
		address _providerTokenAddress, 
		address _desiredTokenAddress, 
		uint256 _providerTokenQuantity,
		uint256 _providerTokenRemainingQuantity,
		uint256 _desiredTokenQuantity,
		uint256 _desiredTokenRemainingQuantity,
		uint256 _indexSelectionFee,
		uint256 _chainNetworkDesiredToken,
		uint256 _chainNetworkProviderToken
		) public
	{
		address selectedAsset = assetList[msg.sender];
		if (selectedAsset == address(0)) {
			address _selectedAsset = address(new CurciferAsset(msg.sender, address(this), _owner));
			assetList[msg.sender] = _selectedAsset;
			providerList.push(msg.sender);
		}

		ICurciferAsset asset = ICurciferAsset(assetList[msg.sender]);

		address _feeToken = feeTokenList[_indexSelectionFee];
		uint256 _feePrice = feePriceList[_indexSelectionFee];

		asset.addOrder(
			_providerTokenAddress, 
			_desiredTokenAddress, 
			_providerTokenQuantity, 
			_providerTokenRemainingQuantity, 
			_desiredTokenQuantity, 
			_desiredTokenRemainingQuantity,
			_chainNetworkDesiredToken,
			_chainNetworkProviderToken,
			_feeToken,
			_feePrice
			);
	}

	function createNewAsset() public {
		address selectedAsset = assetList[msg.sender];
		if (selectedAsset == address(0)) {
			address _selectedAsset = address(new CurciferAsset(msg.sender, address(this), _owner));
			assetList[msg.sender] = _selectedAsset;
			providerList.push(msg.sender);
		}
	}

	function startMyTrade(uint _index) external {
		require((buyerList[msg.sender].isOnGoing == false), "Trade already initiated");
		buyerList[msg.sender].selectedOrderIndex = _index;
		buyerList[msg.sender].isOnGoing = true;
	}

	function cancelMyTrade() external {
		buyerList[msg.sender].isOnGoing = false;
	}

	// TO DO: To be tested
	function finalizedTrade(address _assetOwner, uint _index, uint soldQuantity, uint receivedQuantity) external onlyOwner {
		require((buyerList[msg.sender].isOnGoing == true), "Trade not initiated");
		address selectedAsset = assetList[_assetOwner];
		if (selectedAsset == address(0)) {
			emit AssetOwnerError(1);
			revert UnknownAssetOwner();
		}
		ICurciferAsset(selectedAsset).customerWithdraw(_index, soldQuantity, receivedQuantity);
	} 

	function getCountProviderList() external view returns (uint) {
		return providerList.length;
	}

	function addFeeList(address _token, uint256 _fees) external onlyOwner {
		feeTokenList.push(_token);
		feePriceList.push(_fees);
	}
}