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

    mapping(address => uint) userDeposit;
    mapping(address => uint) userBonus;
    
    address[] userList;

    bool isStarted = false;
    bool isCompleted = false;
    uint totalDeposit;

    address factoryYield;
    address tokenYield;
    address tokenBonus;

    constructor() {
        factoryYield = msg.sender;
    }

    address centralWallet;
     
    function withdrawBonus() external nonReentrant {
        require(isStarted == true, "the yield not started yet");
        uint _amount = userBonus[msg.sender];
        require(_amount > 0, "Amount must be greater than 0");
        userBonus[msg.sender] = 0;
        IERC20(tokenBonus).safeTransfer(msg.sender, _amount);
    }

    function withdrawFunds() external {
        require(isCompleted == true, "Yield still on going, withdraw fund is locked");
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

    }

    function yieldCompleted() external onlyOwner {
        isCompleted = true;
    }

    function yieldStarting() external onlyOwner {
        isStarted = true;
    }

    function distributeBonusYield(
        uint _amount,
        uint _tokenDecimals
    ) external onlyOwner {
        require(_amount > 0, "Need more than 0");
        for (uint i = 0; i < userList.length; i++) {
            address _user = userList[i];
            uint _userRate = userDeposit[_user] / totalDeposit * 100 * _tokenDecimals;
            uint _userBonus = _amount * _userRate;
            userBonus[_user] = _userBonus;
        }
    }

    modifier onlyOwner() {
		require((factoryYield == msg.sender), "Ownable: Caller is not the Owner");
		_;
	}
}