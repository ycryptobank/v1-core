// SPDX-License-Identifier: agpl-3.0


pragma solidity ^0.8.12;

import "./CurciferAsset.sol";

contract CurciferOrderList is ReentrancyGuard {

	mapping(address => address) public assetList;

	uint256 public assetCreatedCounter;

	function createNewOrder(
		address _providerTokenAddress, 
		address _desiredTokenAddress, 
		uint256 _providerTokenQuantity,
		uint256 _providerTokenRemainingQuantity,
		uint256 _desiredTokenQuantity,
		uint256 _desiredTokenRemainingQuantity
		) public
	{
		address selectedAsset = assetList[msg.sender];
		if (selectedAsset == address(0)) {
			address _selectedAsset = address(new CurciferAsset(msg.sender, address(this)));
			assetList[msg.sender] = _selectedAsset;
			assetCreatedCounter ++;
		}
		ICurciferAsset(assetList[msg.sender]).addOrder(
			_providerTokenAddress, 
			_desiredTokenAddress, 
			_providerTokenQuantity, 
			_providerTokenRemainingQuantity, 
			_desiredTokenQuantity, 
			_desiredTokenRemainingQuantity
			);
	}

}