// SPDX-License-Identifier: apgl-3.0

pragma solidity ^0.8.17;

import "./utils/SafeERC20.sol";
import "./utils/ReentrancyGuard.sol";

error NotEnoughAllowanceToPayFee(uint256 requiredAllowance);
error NotEnoughBalanceToPayFee(uint256 balance);
error OrderAlreadyPaid();
error OrderBookLimitSizeNotValid(uint256 limitSize);
error OrderBookCursorOutOfIndex();
error OrderNotCreatedYet();
error OrderCantBeCancelled();
error NotYetPaidFee();
error NotLockedYet();
error withdrawnFlagAlreadyTrue();
error withdrawnAssetAlreadySent();
error assetNotReadyToBeWithdrawn();
error onlyForSameChainWithdraw();

interface IYCBAsset {
    error NotEnoughAllowanceDesiredToken(uint256 requiredAllowance);
    error NotEnoughAllowanceProviderToken(uint256 requiredAllowance);
    error NotEnoughBalanceProviderToken(uint256 balance);
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
    ) external;

    function approveTransactionByAdmin(address _customerAddress) external;

    function customerTrading(
        uint256 _orderId,
        uint256 _soldQuantity,
        uint256 _receivedQuantity,
        uint256 _contractFee,
        address _customerAddress
    ) external payable;
}

contract YCBAsset is ReentrancyGuard, IYCBAsset {
    using SafeERC20 for IERC20;

    event PaidFee(OrderInfo _orderInfo);
    event Deposit(uint256 _idx, OrderInfo _orderInfo);
    event PaidSubcription(uint256 timestamp);

    mapping(uint256 => IYCBAsset.OrderInfo) private orderBook;
    mapping(address => BuyerInfo) private buyerHistory;
    uint256[] orderBookIds;
    address private assetOwner;
    address private orderListContract;
    address private projectOwner;
    address private selectedFeeToken; // selected for Fee Token
    uint256 private selectedFeePrice; // selected for Fee Price
    uint256 private subscriptionPeriod = 4 weeks; // need to subscribe 1 month to trade
    uint256 private selectedSubcriptionFeeToken; // selected for subscription fee token
    uint256 private selectedSubcriptionFeePrice; // selected for subccription fee price
    uint256 private totalOrder = 0;
    bool private isZeroFee = false; // zero fee or with fee switch
    uint256 expiredSubscription;

    constructor(
        address _owner,
        address _orderListContract,
        address _dev
    ) {
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
    ) external onlyForMainContract {
        OrderInfo memory orderInfo;
        orderInfo.providerTokenAddress = _providerTokenAddress;
        orderInfo.providerTokenQuantity = _providerTokenQuantity;
        orderInfo
            .providerTokenRemainingQuantity = _providerTokenRemainingQuantity;
        orderInfo.desiredTokenAddress = _desiredTokenAddress;
        orderInfo.desiredTokenQuantity = _desiredTokenQuantity;
        orderInfo
            .desiredTokenRemainingQuantity = _desiredTokenRemainingQuantity;
        orderInfo.chainNetworkDesiredToken = _chainNetworkDesiredToken;
        orderInfo.chainNetworkProviderToken = _chainNetworkProviderToken;
        orderInfo.orderId = _orderId;
        orderInfo.isReady = false;
        orderInfo.isApproved = false;
        orderInfo.isCreated = true;

        if (isZeroFee) {
            // automatically approved because zero fee
            orderInfo.isApproved = true;
        }

        orderBook[_orderId] = orderInfo;
        orderBookIds.push(_orderId);

        selectedFeeToken = _feeToken;
        selectedFeePrice = _feePrice;
        totalOrder++;
    }

    function paySubsription(uint256 durationMontly) external nonReentrant {
        uint256 allowance = IERC20(selectedFeeToken).allowance(
            assetOwner,
            address(this)
        );
        uint256 balance = IERC20(selectedFeeToken).balanceOf(assetOwner);
        if (allowance <= selectedFeePrice) {
            revert NotEnoughAllowanceToPayFee(selectedSubcriptionFeePrice);
        }
        if (balance <= selectedFeePrice) {
            revert NotEnoughBalanceToPayFee(selectedSubcriptionFeePrice);
        }
        IERC20(selectedFeeToken).safeTransferFrom(
            assetOwner,
            projectOwner,
            selectedSubcriptionFeePrice * durationMontly
        );
        expiredSubscription =
            block.timestamp +
            subscriptionPeriod *
            durationMontly;
        emit PaidSubcription(expiredSubscription);
    }

    // when ZeroFee is not available, need to pay Fee when trading
    function payFee(uint256 _orderId) external nonReentrant {
        uint256 allowance = IERC20(selectedFeeToken).allowance(
            assetOwner,
            address(this)
        );
        uint256 balance = IERC20(selectedFeeToken).balanceOf(assetOwner);
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
        IERC20(selectedFeeToken).safeTransferFrom(
            assetOwner,
            projectOwner,
            selectedFeePrice
        );

        _orderInfo.isApproved = true;
        orderBook[_orderId] = _orderInfo;

        emit PaidFee(_orderInfo);
    }

    function getOrderBook(uint256 _cursor, uint256 _limitSize)
        external
        view
        returns (OrderInfo[] memory)
    {
        if ((_limitSize > 10) && (_limitSize <= 0)) {
            revert OrderBookLimitSizeNotValid(_limitSize);
        }
        uint256 cursor = (_cursor - 1) * _limitSize;
        if (cursor > totalOrder) {
            revert OrderBookCursorOutOfIndex();
        }
        uint256 maxIndexShown = _cursor * _limitSize - 1;
        uint256 copySize = _limitSize;
        if (copySize > totalOrder) {
            copySize = totalOrder;
        }
        OrderInfo[] memory _orderBook = new OrderInfo[](copySize);
        for (uint256 i = cursor; i <= maxIndexShown; i++) {
            if (totalOrder > i) {
                uint256 _getOrderId = orderBookIds[i];
                _orderBook[i % _limitSize] = orderBook[_getOrderId];
            }
        }
        return _orderBook;
    }

    function deposit(uint256 _orderId) external nonReentrant onlyAssetOwner {
        OrderInfo memory _orderInfo = orderBook[_orderId];
        if (!_orderInfo.isCreated) {
            revert OrderNotCreatedYet();
        }
        if (!_orderInfo.isApproved) {
            revert NotYetPaidFee();
        }
        uint256 allowance = IERC20(_orderInfo.providerTokenAddress).allowance(
            msg.sender,
            address(this)
        );
        uint256 balance = IERC20(_orderInfo.providerTokenAddress).balanceOf(
            msg.sender
        );
        if (allowance < _orderInfo.providerTokenQuantity) {
            revert NotEnoughAllowanceProviderToken(allowance);
        }
        if (balance < _orderInfo.providerTokenQuantity) {
            revert NotEnoughBalanceProviderToken(balance);
        }
        IERC20(_orderInfo.providerTokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            balance
        );
        _orderInfo.isReady = true;
        orderBook[_orderId] = _orderInfo;
        emit Deposit(_orderId, _orderInfo);
    }

    function customerTrading(
        uint256 _orderId,
        uint256 _soldQuantity,
        uint256 _receivedQuantity,
        uint256 _contractFee,
        address _customerAddress
    ) external payable nonReentrant onlyForMainContract {
        OrderInfo memory _orderInfo = orderBook[_orderId];
        if (
            _orderInfo.chainNetworkProviderToken ==
            _orderInfo.chainNetworkDesiredToken
        ) {
            uint256 allowance = IERC20(_orderInfo.desiredTokenAddress)
                .allowance(_customerAddress, address(this));
            if (allowance < _orderInfo.desiredTokenQuantity) {
                revert NotEnoughAllowanceDesiredToken(allowance);
            }

            if (!isZeroFee) {
                require(
                    msg.value > _contractFee,
                    "not enough to pay contract fee"
                );
                payable(projectOwner).transfer(_contractFee);
            }

            BuyerInfo memory _buyerInfo = buyerHistory[_customerAddress];
            _buyerInfo.isReady = true;
            _buyerInfo.isWithdrawn = true;
            _buyerInfo.lastInteractionOrderId = _orderId;
            _buyerInfo.soldQuantity = _soldQuantity;

            _orderInfo.providerTokenRemainingQuantity =
                _orderInfo.providerTokenRemainingQuantity -
                _soldQuantity;
            _orderInfo.desiredTokenRemainingQuantity =
                _orderInfo.desiredTokenRemainingQuantity +
                _receivedQuantity;

            orderBook[_orderId] = _orderInfo;
            buyerHistory[_customerAddress] = _buyerInfo;

            IERC20(_orderInfo.desiredTokenAddress).safeTransferFrom(
                _customerAddress,
                assetOwner,
                _receivedQuantity
            );
            IERC20(_orderInfo.providerTokenAddress).safeTransferFrom(
                address(this),
                _customerAddress,
                _soldQuantity
            );
        } else {
            revert onlyForSameChainWithdraw();
        }
    }

    function customerWithdraw(
        uint256 orderId,
        uint256 soldQuantity,
        uint256 receivedQuantity,
        uint256 contractFee
    ) external payable nonReentrant {
        BuyerInfo memory _buyerInfo = buyerHistory[msg.sender];
        if (!_buyerInfo.isReady) {
            revert assetNotReadyToBeWithdrawn();
        }

        OrderInfo memory _orderInfo = orderBook[orderId];
        _orderInfo.providerTokenRemainingQuantity =
            _orderInfo.providerTokenRemainingQuantity -
            soldQuantity;
        _orderInfo.desiredTokenRemainingQuantity =
            _orderInfo.desiredTokenRemainingQuantity +
            receivedQuantity;

        _buyerInfo.isReady = false;

        require(
            msg.value > contractFee,
            "not enough balance to pay transaction fee"
        );
        payable(projectOwner).transfer(contractFee);

        IERC20(_orderInfo.providerTokenAddress).safeTransferFrom(
            address(this),
            msg.sender,
            receivedQuantity
        );
    }

    function cancelOrder(uint256 orderId) external nonReentrant onlyAssetOwner {
        if (!orderBook[orderId].isCreated) {
            revert OrderNotCreatedYet();
        }
        OrderInfo memory _orderInfo = orderBook[orderId];
        if (_orderInfo.isReady) {
            revert OrderCantBeCancelled();
        }
        delete orderBook[orderId];
        totalOrder--;
    }

    function getStatusSubscription() external view returns (bool) {
        return block.timestamp > expiredSubscription;
    }

    function setFeeSwitch(bool flag) external nonReentrant onlyForMainContract {
        isZeroFee = flag;
    }

    function approveTransactionByAdmin(address _customerAddress)
        external
        nonReentrant
        onlyForMainContract
    {
        buyerHistory[_customerAddress].isReady = true;
    }

    function getTotalOrder() external view returns (uint256) {
        return totalOrder;
    }

    modifier onlyForMainContract() {
        require(
            (mainOwner() == msg.sender),
            "Ownable: caller is not the contract"
        );
        _;
    }

    modifier onlyAssetOwner() {
        require(
            (owner() == msg.sender),
            "Ownable: Caller is not the assetOwner"
        );
        _;
    }

    function owner() private view returns (address) {
        return assetOwner;
    }

    function mainOwner() private view returns (address) {
        return orderListContract;
    }
}
