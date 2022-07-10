// SPDX-License-Identifier: agpl-3.0


pragma solidity ^0.8.12;

import "./CurciferAsset.sol";

contract CurciferOrderList is ReentrancyGuard, Ownable {

	mapping(address => address) public orderList;

	function createNewOrder(
		address _providerTokenAddress, 
		address _desiredTokenAddress, 
		uint256 _providerTokenQuantity,
		uint256 _providerTokenRemainingQuantity,
		uint256 _desiredTokenQuantity,
		uint256 _desiredTokenRemainingQuantity
		) public
	{
		address selectedAsset = orderList[msg.sender];
		if (selectedAsset == address(0)) {
			selectedAsset = address(new CurciferAsset(msg.sender));
			orderList[msg.sender] = selectedAsset;
		}
		ICurciferAsset(selectedAsset).addOrder(
			_providerTokenAddress, 
			_desiredTokenAddress, 
			_providerTokenQuantity, 
			_providerTokenRemainingQuantity, 
			_desiredTokenQuantity, 
			_desiredTokenRemainingQuantity
			);
	}

}