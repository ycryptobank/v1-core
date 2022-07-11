// SPDX-License-Identifier: apgl-3.0

pragma solidity ^0.8.12;

import "./utils/Ownable.sol";
import "./utils/ReentrancyGuard.sol";
import "./utils/SafeERC20.sol";


interface ICurciferAsset {
	function addOrder (
		address _providerTokenAddress, 
		address _desiredTokenAddress, 
		uint256 _providerTokenQuantity,
		uint256 _providerTokenRemainingQuantity,
		uint256 _desiredTokenQuantity,
		uint256 _desiredTokenRemainingQuantity
	) external;
}

contract CurciferAsset is ReentrancyGuard, ICurciferAsset {

	struct OrderInfo {
		address[] listOfBuyerWallet;
		address providerTokenAddress;
		uint256 providerTokenQuantity;
		uint256 providerTokenRemainingQuantity;
		address desiredTokenAddress;
		uint256 desiredTokenQuantity;
		uint256 desiredTokenRemainingQuantity;
		bool isReady;
	}

	OrderInfo[] private providerOrders;

	address private assetOwner;

	constructor(address _owner) {
		assetOwner = _owner;
	}

	function addOrder(
		address _providerTokenAddress, 
		address _desiredTokenAddress, 
		uint256 _providerTokenQuantity,
		uint256 _providerTokenRemainingQuantity,
		uint256 _desiredTokenQuantity,
		uint256 _desiredTokenRemainingQuantity
		) external onlyOwner
	{
		OrderInfo memory orderInfo;
		orderInfo.providerTokenAddress = _providerTokenAddress;
		orderInfo.providerTokenQuantity = _providerTokenQuantity;
		orderInfo.providerTokenRemainingQuantity = _providerTokenRemainingQuantity;
		orderInfo.desiredTokenAddress = _desiredTokenAddress;
		orderInfo.desiredTokenQuantity = _desiredTokenQuantity;
		orderInfo.desiredTokenRemainingQuantity = _desiredTokenRemainingQuantity;

		providerOrders.push(orderInfo);
	}

	modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
	
	function owner() public view virtual returns (address) {
        return assetOwner;
    }
}