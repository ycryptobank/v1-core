// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract CurciferDex is ReentrancyGuard {

    using SafeERC20 for IERC20;

    // Official first erc20 for fee, Fans of Million Token by TechLead;
    address private constant MM_TOKEN_CONTRACT = 0x993163CaD35162fB579D7B64e6695cB076EF5064;

    address owner;

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
        owner = msg.sender;
        tokenContracts.push(MM_TOKEN_CONTRACT);
        // 0.01 MM;
        fees.push(10^16);
    }

    function tranferContractOwnership() public onlyOwner {
        owner = msg.sender;
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
        IERC20(_feeTokenAddress).safeTransferFrom(msg.sender, owner, _fee);

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

    function removeProviderTrade(uint256 _exchangeIndex) public nonReentrant {
        ProviderData[] memory providerExchange = activePersonalProviders[msg.sender];
        require(providerExchange.length == 0, "Provider address has no data");
        require(_exchangeIndex < providerExchange.length, "This execution is trying to execute index nothing");
        
        ProviderData memory exchangeData = providerExchange[_exchangeIndex];   
        require(IERC20(exchangeData.targetToken).allowance(msg.sender, address(this)) >= exchangeData.targetTokenValue, "Target token allowance target not enough");
        require(IERC20(exchangeData.targetToken).balanceOf(msg.sender) >= exchangeData.targetTokenValue, "Target Token Balance not enough");
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

    function getMyExchangeData() external view returns (ProviderData[] memory) {
        return activePersonalProviders[msg.sender];
    }

    modifier onlyOwner() {
        require(
            owner == msg.sender,
            "Only owner is authorized for this option"
        );
        _;
    }
}
