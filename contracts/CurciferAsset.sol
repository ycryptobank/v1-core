// SPDX-License-Identifier: apgl-3.0

pragma solidity ^0.8.12;

import "./utils/ReentrancyGuard.sol";
import "./utils/SafeERC20.sol";

error NotEnoughAllowanceToPayFee(uint requiredAllowance);
error NotEnoughBalanceToPayFee(uint balance);
error OrderAlreadyPaid();
error OrderBookLimitSizeNotValid(uint limitSize);
error OrderBookCursorOutOfIndex();
error OrderNotCreatedYet();
error OrderCantBeCancelled();
error NotYetPaidFee();
error NotLockedYet();
error withdrawnFlagAlreadyTrue();
error withdrawnAssetAlreadySent();
error assetNotReadyToBeWithdrawn();

interface ICurciferAsset {
	error NotEnoughAllowanceDesiredToken(uint requiredAllowance);
	error NotEnoughAllowanceProviderToken(uint requiredAllowance);
	error NotEnoughBalanceProviderToken(uint balance);
	struct OrderInfo {
		address providerTokenAddress;
		address desiredTokenAddress;
		uint256 orderId;
		uint256 providerTokenQuantity;
		uint256 providerTokenRemainingQuantity;
		uint256 desiredTokenQuantity;
		uint256 desiredTokenRemainingQuantity;
		uint256 chainNetworkDesiredToken;
		uint256 chainNetworkProviderToken;
		bool isReady;
		bool isApproved;
		bool isCreated;
	}
	struct BuyerInfo {
		uint256 lastInteractionOrderId;
		uint256 soldQuantity;
		bool isWithdrawn;
		bool isReady;
	}
	function addOrder (
		address _providerTokenAddress, 
		address _desiredTokenAddress, 
		uint256 _providerTokenQuantity,
		uint256 _providerTokenRemainingQuantity,
		uint256 _desiredTokenQuantity,
		uint256 _desiredTokenRemainingQuantity,
		uint256 _chainNetworkDesiredToken,
		uint256 _chainNetworkProviderToken,
		uint256 _orderId,
		address _feeToken,
		uint256 _feePrice
	) external;
	function approveTransactionByAdmin(address _customerAddress) external;
	function customerTrading(uint _orderId, uint _soldQuantity, uint _receivedQuantity, uint _contractFee, address _customerAddress) external payable;
}

contract CurciferAsset is ReentrancyGuard, ICurciferAsset {
	using SafeERC20 for IERC20;

	event PaidFee(
		OrderInfo _orderInfo
	);
	event Deposit(
		uint _idx,
		OrderInfo _orderInfo
	);

	mapping (uint256 => ICurciferAsset.OrderInfo) private orderBook;
	mapping (address => BuyerInfo) private buyerHistory;
	uint256[] orderBookIds;
	address private assetOwner;
	address private orderListContract;
	address private projectOwner;
	address private selectedFeeToken;
	uint256 private selectedFeePrice;
	uint private totalOrder = 0;

	constructor(address _owner, address _orderListContract, address _dev) {
		assetOwner = _owner;
		orderListContract = _orderListContract;
		projectOwner = _dev;
	}

	function addOrder(
		address _providerTokenAddress, 
		address _desiredTokenAddress, 
		uint256 _providerTokenQuantity,
		uint256 _providerTokenRemainingQuantity,
		uint256 _desiredTokenQuantity,
		uint256 _desiredTokenRemainingQuantity,
		uint256 _chainNetworkDesiredToken,
		uint256 _chainNetworkProviderToken,
		uint256 _orderId,
		address _feeToken,
		uint256 _feePrice
		) external onlyForMainContract
	{
		OrderInfo memory orderInfo;
		orderInfo.providerTokenAddress = _providerTokenAddress;
		orderInfo.providerTokenQuantity = _providerTokenQuantity;
		orderInfo.providerTokenRemainingQuantity = _providerTokenRemainingQuantity;
		orderInfo.desiredTokenAddress = _desiredTokenAddress;
		orderInfo.desiredTokenQuantity = _desiredTokenQuantity;
		orderInfo.desiredTokenRemainingQuantity = _desiredTokenRemainingQuantity;
		orderInfo.chainNetworkDesiredToken = _chainNetworkDesiredToken;
		orderInfo.chainNetworkProviderToken = _chainNetworkProviderToken;
		orderInfo.orderId = _orderId;
		orderInfo.isReady = false;
		orderInfo.isApproved = false;
		orderInfo.isCreated = true;

		orderBook[_orderId] = orderInfo;
		orderBookIds.push(_orderId);

		selectedFeeToken = _feeToken;
		selectedFeePrice = _feePrice;
		totalOrder ++;
	}

	function payFee(uint256 _orderId) external nonReentrant {
		uint allowance = IERC20(selectedFeeToken).allowance(assetOwner, address(this));
		uint balance = IERC20(selectedFeeToken).balanceOf(assetOwner);
		if (allowance <= selectedFeePrice) {
			revert NotEnoughAllowanceToPayFee(selectedFeePrice);
		}
		if (balance <= selectedFeePrice) {
			revert NotEnoughBalanceToPayFee(selectedFeePrice);
		}
		OrderInfo memory _orderInfo = orderBook[_orderId];
		if (_orderInfo.isApproved == true) {
			revert OrderAlreadyPaid();
		}
		IERC20(selectedFeeToken).safeTransferFrom(assetOwner, projectOwner, selectedFeePrice);

		_orderInfo.isApproved = true;
		orderBook[_orderId] = _orderInfo;

		emit PaidFee(_orderInfo);
	}

	function getOrderBook(uint _cursor, uint _limitSize) external view returns (OrderInfo[] memory) {
		if ((_limitSize > 10) && (_limitSize <= 0)){ revert OrderBookLimitSizeNotValid(_limitSize); }
		uint cursor = (_cursor - 1) * _limitSize;
		if (cursor > totalOrder){ revert OrderBookCursorOutOfIndex(); }
		uint maxIndexShown = _cursor * _limitSize - 1;
		uint copySize = _limitSize;
		if (copySize > totalOrder) {
			copySize = totalOrder;
		}
		OrderInfo[] memory _orderBook = new OrderInfo[](copySize);
		for (uint i = cursor; i <= maxIndexShown; i++) {
			if (totalOrder > i) {
				uint256 _getOrderId = orderBookIds[i];
				_orderBook[i % _limitSize] = orderBook[_getOrderId];
			}
		}
		return _orderBook;
	}

	function deposit(uint _orderId) external nonReentrant onlyAssetOwner {
		OrderInfo memory _orderInfo = orderBook[_orderId];
		if (!_orderInfo.isCreated) {
			revert OrderNotCreatedYet();
		}
		if (!_orderInfo.isApproved) {
			revert NotYetPaidFee();
		}
		uint allowance = IERC20(_orderInfo.providerTokenAddress).allowance(msg.sender, address(this));
		uint balance = IERC20(_orderInfo.providerTokenAddress).balanceOf(msg.sender);
		if (allowance < _orderInfo.providerTokenQuantity) {
			revert NotEnoughAllowanceProviderToken(allowance);
		}
		if (balance < _orderInfo.providerTokenQuantity) {
			revert NotEnoughBalanceProviderToken(balance);
		}
		IERC20(_orderInfo.providerTokenAddress).safeTransferFrom(msg.sender, address(this), balance);
		_orderInfo.isReady = true;
		orderBook[_orderId] = _orderInfo;
		emit Deposit(_orderId, _orderInfo);
	}

	function customerTrading(uint _orderId, uint _soldQuantity, uint _receivedQuantity, uint _contractFee, address _customerAddress) external payable nonReentrant onlyForMainContract {
		OrderInfo memory _orderInfo = orderBook[_orderId];
		if (_orderInfo.chainNetworkProviderToken == _orderInfo.chainNetworkDesiredToken) {

			uint allowance = IERC20(_orderInfo.desiredTokenAddress).allowance(_customerAddress, address(this));
			if (allowance < _orderInfo.desiredTokenQuantity) {
				revert NotEnoughAllowanceDesiredToken(allowance);
			}

			require(msg.value > _contractFee, "not enough to pay contract fee");
			payable(projectOwner).transfer(_contractFee);

			BuyerInfo memory _buyerInfo = buyerHistory[_customerAddress];
			_buyerInfo.isReady = false;
			_buyerInfo.isWithdrawn = true;
			_buyerInfo.lastInteractionOrderId = _orderId;
			_buyerInfo.soldQuantity = _soldQuantity;

			_orderInfo.providerTokenRemainingQuantity = _orderInfo.providerTokenRemainingQuantity - _soldQuantity;
			_orderInfo.desiredTokenRemainingQuantity = _orderInfo.desiredTokenRemainingQuantity + _receivedQuantity;

			orderBook[_orderId] = _orderInfo;
			buyerHistory[_customerAddress] = _buyerInfo;

			IERC20(_orderInfo.desiredTokenAddress).safeTransferFrom(_customerAddress, assetOwner, _receivedQuantity);
			IERC20(_orderInfo.providerTokenAddress).safeTransferFrom(address(this), _customerAddress, _soldQuantity);
			
		} else {
			BuyerInfo memory _buyerInfo = buyerHistory[_customerAddress];
			_buyerInfo.isReady = false;
			_buyerInfo.isWithdrawn = false;
			_buyerInfo.lastInteractionOrderId = _orderId;
			_buyerInfo.soldQuantity = _soldQuantity;
			// TO DO: check admin
		}
	}

	function customerWithdraw(uint orderId, uint soldQuantity, uint receivedQuantity, uint contractFee) external payable nonReentrant {
		BuyerInfo memory _buyerInfo = buyerHistory[msg.sender];
		if (!_buyerInfo.isReady) {
			revert assetNotReadyToBeWithdrawn();
		}
		
		OrderInfo memory _orderInfo = orderBook[orderId];
		_orderInfo.providerTokenRemainingQuantity = _orderInfo.providerTokenRemainingQuantity - soldQuantity;
		_orderInfo.desiredTokenRemainingQuantity = _orderInfo.desiredTokenRemainingQuantity + receivedQuantity;

		_buyerInfo.isReady = false;

		require(msg.value > contractFee, "not enough balance to pay transaction fee");
		payable(projectOwner).transfer(contractFee);

		IERC20(_orderInfo.providerTokenAddress).safeTransferFrom(address(this), msg.sender, receivedQuantity);
	}

	function customerWithdrawOnChain() external nonReentrant {
		// TO DO: for withdraw customer with same chain network
	}

	function cancelOrder(uint orderId) external nonReentrant onlyAssetOwner {
		if (!orderBook[orderId].isCreated) {
			revert OrderNotCreatedYet();
		}
		OrderInfo memory _orderInfo = orderBook[orderId];
		if (_orderInfo.isReady) {
			revert OrderCantBeCancelled();
		}
		delete orderBook[orderId];
		totalOrder --;
	}

	function approveTransactionByAdmin(address _customerAddress) external nonReentrant onlyForMainContract {
		buyerHistory[_customerAddress].isReady = true;
	}

	function getTotalOrder() external view returns (uint) {
		return totalOrder;
	}

	modifier onlyForMainContract() {
        require(( mainOwner() == msg.sender), "Ownable: caller is not the contract");
        _;
    }

	modifier onlyAssetOwner() {
		require((owner() == msg.sender), "Ownable: Caller is not the assetOwner");
		_;
	}
	
	function owner() private view returns (address) {
        return assetOwner;
    }

	function mainOwner() private view returns (address) {
        return orderListContract;
    }
}