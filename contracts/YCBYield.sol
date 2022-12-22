// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.17;
import "./interfaces/IYCBYield.sol";
import "./utils/SafeERC20.sol";
import "./utils/ReentrancyGuard.sol";

contract YCBYield is IYCBYield, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint yieldRate = 15; // 0.15% default minimum yield
    uint depositFeeRate = 100; // 1% deposit fee
    uint totalPercentage = 10000; // 100%
    uint frozenPeriod = 1 days;
    uint startYield;

    mapping(address => uint) userDeposit;
    mapping(address => uint) userBonus;
    
    address[] userList;

    bool isStarted = false;
    bool isCompleted = false;
    bool isPause = false;
    uint totalDeposit;

    address tokenYield;
    address tokenBonus;

    address public factoryYield;
    address centralWallet;

    constructor(
        address _centralWallet,
        address _tokenYield,
        address _tokenBonus,
        uint _yieldRate, 
        uint _depositRate,
        uint _frozenPeriods
    ) {
        factoryYield = msg.sender;
        tokenYield = _tokenYield;
        tokenBonus = _tokenBonus;
        yieldRate = _yieldRate;
        depositFeeRate = _depositRate;
        frozenPeriod = _frozenPeriods * 1 days;
        startYield = block.timestamp;
        centralWallet = _centralWallet;
    }
     
    function withdrawBonus() external nonReentrant {
        require(isStarted == true, "the yield not started yet");
        require(isPause == false, "Yield paused for withdrawal");
        uint _amount = userBonus[msg.sender];
        require(_amount > 0, "Amount must be greater than 0");
        userBonus[msg.sender] = 0;
        IERC20(tokenBonus).safeTransfer(msg.sender, _amount);
    }

    function withdrawFunds() external nonReentrant {
        require(isCompleted == true, "Yield still on going, withdraw fund is locked");
        require(
            block.timestamp - startYield > frozenPeriod,
            "Freezer lock up not finished yet"
        );
        require(isPause == false, "Yield paused for withdrawal");
        uint _amount = userBonus[msg.sender];
        require(_amount > 0, "Amount must be greater than 0");
        userDeposit[msg.sender] = 0;
        IERC20(tokenYield).safeTransfer(msg.sender, _amount);
    }
    
    function depositYield(
        uint _amount
    ) external returns (uint _totalDeposit) {
        require(_amount > 0, "Amount must be greater than 0");
        require(
            IERC20(tokenYield).allowance(msg.sender, address(this)) >=
                _amount,
            "Insufficient allowance"
        );
        require(isPause == false, "Yield paused for deposit");
        uint256 depositFee = (_amount * depositFeeRate) / totalPercentage;
        uint256 amountToDeposit = _amount - depositFee;
        IERC20(tokenYield).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        IERC20(tokenYield).safeTransfer(centralWallet, depositFee);
        if (userDeposit[msg.sender] == 0) {
            userList.push(msg.sender);
        }
        userDeposit[msg.sender] = amountToDeposit;
        totalDeposit += amountToDeposit;
        _totalDeposit = amountToDeposit;
    }
    
    function emergencyTransfer(
        address _userPath,
        address _token,
        uint _amount
    ) external onlyOwner {
        require(_amount > 0, "amount need more than 0");
        require(getBalance(_token) > 0, "no balance of this token");
        IERC20(_token).safeTransfer(_userPath, _amount);
    }

    function pauseYield(
        bool _isPaused
    ) external onlyOwner {
        isPause = _isPaused;
    }

    function yieldCompleted() external onlyFactory {
        isCompleted = true;
    }

    function yieldStarting() external onlyFactory {
        isStarted = true;
    }

    function distributeBonusYield(
        uint[] memory _amountList
    ) external onlyFactory {
        for (uint i = 0; i < userList.length; i++) {
            address _user = userList[i];
            userBonus[_user] = _amountList[i];
        }
    }

    function getTokenBonusDecimals() external view returns (uint _amount) {
        _amount = IERC20(tokenBonus).decimals();
    }

    function getTotalDeposit() external view returns (uint _amount) {
        _amount = totalDeposit;
    }

    function getUserDeposit() external view returns (uint _amount) {
        _amount = userDeposit[msg.sender];
    }

    function getUserBonus() external view returns (uint _amount) {
        _amount = userBonus[msg.sender];
    }

    function getCurrentYieldTime() external view returns (
        uint256 _currentYieldTime,
        uint256 _frozenPeriod
    ) {
        _currentYieldTime = block.timestamp - startYield;
        _frozenPeriod = frozenPeriod;
    }

    function getBalance(
        address token
    ) private view returns (uint amount) {
        amount = IERC20(token).balanceOf(address(this));
    }

    function getTokenYield() external view returns (address _tokenYield) {
        _tokenYield = tokenYield;
    }

    function getTokenBonus() external view returns (address _tokenBonus) {
        _tokenBonus = tokenBonus;
    }

    modifier onlyOwner() {
		require((centralWallet == msg.sender), "Ownable: Caller is not the Owner");
		_;
	}

    modifier onlyFactory() {
        require((factoryYield == msg.sender), "Ownable: Caller is not the Factory");
		_;
    }
}