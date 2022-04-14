// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.12;

import "./utils/SafeERC20.sol";
import "./utils/Ownable.sol";
import "./utils/ReentrancyGuard.sol";

contract CurciferDex is ReentrancyGuard, Ownable {

    using SafeERC20 for IERC20;

    // Official first erc20 for fee, Fans of Million Token by TechLead;
    address private constant MM_TOKEN_CONTRACT = 0x993163CaD35162fB579D7B64e6695cB076EF5064;

    // contain active provider data
    mapping(address => ProviderData[]) public activePersonalProviders;
    // To get all providers
    address[] personalProviders;

    // contain all customer data who interract with dex
    mapping(address => CurciferRewards) royalCustomers;


    // Accepted Token for pay fee
    address[] tokenContracts;
    // Accepted Token Fee
    uint256[] fees;

    // Provider Data
    struct ProviderData {
        address providerToken;
        uint256 providerTokenValue;
        address targetToken;
        uint256 targetTokenValue;
        uint256 selectedErc20IndexForPayFee;
        address orderTaker;
    }

    // Rewards
    struct CurciferRewards {
        address customer;
        uint256 point;
    }

    constructor() {
        tokenContracts.push(MM_TOKEN_CONTRACT);
        // 0.01 MM;
        fees.push(10^16);
    }

    function addTokenAddress(address _erc20FeeTokenAddress, uint256 _fee) public onlyOwner {
        tokenContracts.push(_erc20FeeTokenAddress);
        fees.push(_fee);
    }

    function createPersonalProvider(
        IERC20 _providerToken,
        uint256 _providerTokenValue, 
        IERC20 _targetToken,
        uint256 _targetTokenValue, 
        uint256 _selectedErc20IndexForPayFee
        ) public {
        require(_providerToken.balanceOf(msg.sender) >= _providerTokenValue, "Provider Token Balance not enough");
        require(_selectedErc20IndexForPayFee < tokenContracts.length, "Provider select invalid fee index");

        uint256 _fee = fees[_selectedErc20IndexForPayFee];
        address _feeTokenAddress = tokenContracts[_selectedErc20IndexForPayFee];
        require(_providerToken.allowance(msg.sender, address(this)) >= _providerTokenValue, "Provider token not enough allowance");
        require(IERC20(_feeTokenAddress).allowance(msg.sender, address(this)) >= _fee, "Provider fee token not enough allowance");
        require(IERC20(_feeTokenAddress).balanceOf(msg.sender) >= _fee, "Provider fee token Balance not enough");

        // pay fee
        IERC20(_feeTokenAddress).safeTransferFrom(msg.sender, _owner, _fee);

        // put provider token to contract
        IERC20(_providerToken).safeTransferFrom(msg.sender, address(this), _providerTokenValue);

        // put to provider data pool
        activePersonalProviders[msg.sender].push(ProviderData(
            address(_providerToken), 
            _providerTokenValue, 
            address(_targetToken), 
            _targetTokenValue, 
            _selectedErc20IndexForPayFee, 
            address(0x0)));
        
        // put to collection for first time only
        if (activePersonalProviders[msg.sender].length == 1) {
            personalProviders.push(msg.sender);
        }
    }

    function fulfillPersonalTradeOrder(address _providerAddress, uint256 _exchangeIndex) public {
        require(msg.sender != _providerAddress, "Provider can not fulfill own order");

        ProviderData[] memory providerExchange = activePersonalProviders[_providerAddress];
        require(_exchangeIndex < providerExchange.length, "This execution is trying to execute index nothing");
        
        ProviderData memory exchangeData = providerExchange[_exchangeIndex];   
        require(IERC20(exchangeData.targetToken).allowance(msg.sender, address(this)) >= exchangeData.targetTokenValue, "Target token allowance target not enough");
        require(IERC20(exchangeData.targetToken).balanceOf(msg.sender) >= exchangeData.targetTokenValue, "Target Token Balance not enough");
        require(exchangeData.orderTaker == address(0x0), "This order was already fulfilled");
        
        exchangeData.orderTaker = msg.sender;
        activePersonalProviders[_providerAddress][_exchangeIndex] = exchangeData;
        IERC20(exchangeData.targetToken).safeTransferFrom(msg.sender, address(this), exchangeData.targetTokenValue);
    }

    function executePersonalTrade(address _providerAddress, uint256 _exchangeIndex) public nonReentrant {
        require(msg.sender != _providerAddress, "Provider can not execute own order");

        ProviderData[] memory providerExchange = activePersonalProviders[_providerAddress];
        require(_exchangeIndex < providerExchange.length, "This execution is trying to execute invalid index");

        ProviderData memory exchangeData = providerExchange[_exchangeIndex];
        require(exchangeData.orderTaker == msg.sender, "This order is not for this address");
        require(exchangeData.orderTaker != address(0x0), "The order is not fulfill yet");
        
        uint256 _activePersonalProviderLength = activePersonalProviders[_providerAddress].length;

        if ( _activePersonalProviderLength > 0) {
            // swap last index to selected index
            activePersonalProviders[_providerAddress][_exchangeIndex] = activePersonalProviders[_providerAddress][_activePersonalProviderLength - 1];
        }
        // remove last index
        activePersonalProviders[_providerAddress].pop();

        
        IERC20(exchangeData.targetToken).safeTransfer(_providerAddress, exchangeData.targetTokenValue);
        IERC20(exchangeData.providerToken).safeTransfer(msg.sender, exchangeData.providerTokenValue);
    }

    function cancelOrderTrade(address _providerAddress, uint256 _exchangeIndex) public nonReentrant {
        require(msg.sender != _providerAddress, "Provider can not execute own order");
        ProviderData[] memory providerExchange = activePersonalProviders[_providerAddress];
        require(_exchangeIndex < providerExchange.length, "This execution is trying to execute index nothing");
        
        ProviderData memory exchangeData = providerExchange[_exchangeIndex];   
        require(IERC20(exchangeData.targetToken).allowance(msg.sender, address(this)) >= exchangeData.targetTokenValue, "Target token allowance target not enough");
        require(IERC20(exchangeData.targetToken).balanceOf(msg.sender) >= exchangeData.targetTokenValue, "Target Token Balance not enough");
        require(exchangeData.orderTaker == msg.sender, "This order is not for you");
        
        exchangeData.orderTaker = address(0x0);
        activePersonalProviders[_providerAddress][_exchangeIndex] = exchangeData;
        IERC20(exchangeData.targetToken).safeTransfer(msg.sender, exchangeData.targetTokenValue);
    }

    function cancelProviderTrade(uint256 _exchangeIndex) public nonReentrant {
        ProviderData[] memory providerExchange = activePersonalProviders[msg.sender];
        require(providerExchange.length > 0, "Provider address has no data");
        require(_exchangeIndex < providerExchange.length, "This execution is trying to execute index nothing");
        
        ProviderData memory exchangeData = providerExchange[_exchangeIndex];   
        require(exchangeData.orderTaker == address(0x0), "This order is still in progress");
        
        uint256 _activePersonalProviderLength = activePersonalProviders[msg.sender].length;
        if ( _activePersonalProviderLength > 0) {
            // swap last index to selected index
            activePersonalProviders[msg.sender][_exchangeIndex] = activePersonalProviders[msg.sender][_activePersonalProviderLength - 1];
        }
        activePersonalProviders[msg.sender].pop();
        // give back provider token to provider
        IERC20(exchangeData.providerToken).safeTransfer(msg.sender, exchangeData.providerTokenValue);
    }

    function getPersonalProvider(uint _page, uint _limitSize) external view returns (address[] memory) {
        require(_page > 0, "page start from 1");
        require(_limitSize <= 10, "limit max is 10");
        uint cursor = (_page - 1) * _limitSize;
        address[] memory _personalProviders = new address[](_limitSize);
        for (uint i = cursor; i < (_page * _limitSize - 1); i++){
            _personalProviders[i % _limitSize] = personalProviders[i];
        } 
        return _personalProviders;
    }

    // TODO: Get Exchange Data list with param provider address
    function getMyExchangeData() external view returns (ProviderData[] memory) {
        return activePersonalProviders[msg.sender];
    }
}
