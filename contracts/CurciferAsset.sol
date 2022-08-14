// SPDX-License-Identifier: apgl-3.0

pragma solidity ^0.8.12;

import "./utils/ReentrancyGuard.sol";
import "./utils/SafeERC20.sol";

error NotEnoughAllowanceToPayFee(uint requiredAllowance);
error NotEnoughBalanceToPayFee(uint balance);
error OrderAlreadyPaid();
error OrderBookLimitSizeNotValid(uint limitSize);
error OrderBookCursorOutOfIndex();
error NotYetPaidFee();
error NotLockedYet();

interface ICurciferAsset {
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
		// maybe no need this property of paidFeeTxId
		bytes32 paidFeeTxId;
		bool isReady;
		bool isApproved;
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
		address _feeToken,
		uint256 _feePrice
	) external;
	function deposit(uint idx) external;
	function customerDeposit() external;
	function withdraw() external;
	function customerWithdraw(uint idx, uint soldQuantity, uint receivedQuantity) external;
	function getOrderBook(uint256 page, uint256 limitSize) external view returns (OrderInfo[] memory);
	function payFee(uint256 index) external;
	function getAssetOwner() external view returns (address);
}

contract CurciferAsset is ReentrancyGuard, ICurciferAsset {
	using SafeERC20 for IERC20;

	event PaidFee(
		bytes32 indexed txId,
		OrderInfo _orderInfo
	);

	ICurciferAsset.OrderInfo[] private orderBook;
	mapping (uint256 => uint256) private orderInfoKeys;
	address private assetOwner;
	address private orderListContract;
	address private projectOwner;
	address private selectedFeeToken;
	uint256 private selectedFeePrice;
	uint private cnonce = 0;

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
		orderInfo.orderId = orderBook.length;
		orderInfo.isReady = false;
		orderInfo.isApproved = false;

		orderBook.push(orderInfo);
		orderInfoKeys[orderInfo.orderId] = generateRandomKey();

		selectedFeeToken = _feeToken;
		selectedFeePrice = _feePrice;
	}

	function payFee(uint256 _index) external nonReentrant {
		uint allowance = IERC20(selectedFeeToken).allowance(assetOwner, address(this));
		uint balance = IERC20(selectedFeeToken).balanceOf(assetOwner);
		if (allowance <= selectedFeePrice) {
			revert NotEnoughAllowanceToPayFee(selectedFeePrice);
		}
		if (balance <= selectedFeePrice) {
			revert NotEnoughBalanceToPayFee(selectedFeePrice);
		}
		OrderInfo memory _orderInfo = orderBook[_index];
		if (_orderInfo.isApproved == true) {
			revert OrderAlreadyPaid();
		}
		IERC20(selectedFeeToken).safeTransferFrom(assetOwner, projectOwner, selectedFeePrice);

		_orderInfo.isApproved = true;
		_orderInfo.paidFeeTxId = getTxId();
		orderBook[_index] = _orderInfo;

		emit PaidFee(_orderInfo.paidFeeTxId, _orderInfo);
	}

	function getOrderBook(uint _cursor, uint _limitSize) external view returns (OrderInfo[] memory) {
		if ((_limitSize > 10) && (_limitSize <= 0)){ revert OrderBookLimitSizeNotValid(_limitSize); }
		uint cursor = (_cursor - 1) * _limitSize;
		if (cursor > orderBook.length){ revert OrderBookCursorOutOfIndex(); }
		uint maxIndexShown = _cursor * _limitSize - 1;
		uint copySize = _limitSize;
		if (copySize > orderBook.length) {
			copySize = orderBook.length;
		}
		OrderInfo[] memory _orderBook = new OrderInfo[](copySize);
		for (uint i = cursor; i < maxIndexShown; i++) {
			if (orderBook.length > i) {
				_orderBook[i % _limitSize] = orderBook[i];
			}
		}
		return _orderBook;
	}

	function deposit(uint idx) external onlyAssetOwner {
		OrderInfo memory _orderInfo = orderBook[idx];
		if (!_orderInfo.isApproved) {
			revert NotYetPaidFee();
		}
		uint allowance = IERC20(_orderInfo.providerTokenAddress).allowance(msg.sender, address(this));
		uint balance = IERC20(_orderInfo.providerTokenAddress).balanceOf(msg.sender);
		if (allowance <= _orderInfo.providerTokenQuantity) {
			revert NotEnoughAllowanceProviderToken(allowance);
		}
		if (balance <= _orderInfo.providerTokenQuantity) {
			revert NotEnoughBalanceProviderToken(balance);
		}
		IERC20(_orderInfo.providerTokenAddress).safeTransferFrom(msg.sender, address(this), balance);
		_orderInfo.isReady = true;
		orderBook[idx] = _orderInfo;
	}

	function customerDeposit() external {
		// TO DO: deposit for customer
	}

	function withdraw() external nonReentrant onlyAssetOwner {
		// TO DO: for withdraw asset owner
	}

	function customerWithdraw(uint idx, uint soldQuantity, uint receivedQuantity) external nonReentrant onlyForMainContract {
		// issue: how to know other chain already deposited
		// fix: by using server side owner account to approve finalization.
		OrderInfo memory _orderInfo = orderBook[idx];
		_orderInfo.providerTokenRemainingQuantity = _orderInfo.providerTokenRemainingQuantity - soldQuantity;
		_orderInfo.desiredTokenRemainingQuantity = _orderInfo.desiredTokenRemainingQuantity + receivedQuantity;
		// TO DO : safe transfer token from this contract to customer address
	}

	function customerWithdrawOnChain() external nonReentrant {
		// TO DO: for withdraw customer with same chain network
	}

	function generateRandomKey() private returns (uint256) {
		cnonce ++;
		return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, cnonce)));
	}

	function getTxId() private view returns (bytes32) {
		return keccak256(abi.encode(msg.sender, block.timestamp));
	}

	function getAssetOwner() external view returns (address) {
		return assetOwner;
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