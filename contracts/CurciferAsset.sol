// SPDX-License-Identifier: apgl-3.0

pragma solidity ^0.8.12;

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

	OrderInfo[] private orderBook;

	address private assetOwner;
	address private orderListContract;

	constructor(address _owner, address _orderListContract) {
		assetOwner = _owner;
		orderListContract = _orderListContract;
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

		orderBook.push(orderInfo);
	}

	function getOrderBooks(uint _page, uint _limitSize) external view returns (OrderInfo[] memory) {
		require(_page > 0, "page start from 0");
		require(_limitSize <= 10, "size limit is 10");
		uint cursor = (_page - 1) * _limitSize;
		OrderInfo[] memory _orderBook = new OrderInfo[](_limitSize);
		for (uint i = cursor; i < (_page * _limitSize - 1); i++) {
			_orderBook[i % _limitSize] = orderBook[i];
		}
		return _orderBook;
	}

	modifier onlyOwner() {
        require((owner() == msg.sender) || ( mainOwner() == msg.sender), "Ownable: caller is not the owner");
        _;
    }
	
	function owner() public view virtual returns (address) {
        return assetOwner;
    }

	function mainOwner() public view virtual returns (address) {
        return orderListContract;
    }
}