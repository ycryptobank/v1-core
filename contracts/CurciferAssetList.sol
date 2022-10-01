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

	mapping(address => address) public assetList;

	address[] private providerList;
	address[] private feeTokenList;
	uint256[] private feePriceList;
	uint256 private nonce;
	uint256 private contractFee = 0.01 ether;

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
			createOrderId(),
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

	function customerTrading(address _assetOwner, uint _orderId, uint _soldQuantity, uint _receivedQuantity) public {
		address selectedAsset = assetList[_assetOwner];
		if (selectedAsset == address(0)) {
			emit AssetOwnerError(1);
			revert UnknownAssetOwner();
		}
		ICurciferAsset(selectedAsset).customerTrading(_orderId, _soldQuantity, _receivedQuantity, contractFee, msg.sender);
	}

	function getCountProviderList() external view returns (uint) {
		return providerList.length;
	}

	function addFeeList(address _token, uint256 _fees) external onlyOwner {
		feeTokenList.push(_token);
		feePriceList.push(_fees);
	}

	function updateContractFee(uint256 _fee) external onlyOwner{
		contractFee = _fee;
	}

	function createOrderId() private returns (uint256) {
		nonce ++;
		return uint256(keccak256(abi.encode(msg.sender, block.timestamp, nonce)));
	}
}