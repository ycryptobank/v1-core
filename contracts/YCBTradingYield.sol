// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./utils/ReentrancyGuard.sol";

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract YCBTradingYield is ReentrancyGuard {
    address public owner;
    address public stakeToken;
    address public yieldToken;

    uint256 public totalStaked;
    uint256 public ownerDeposit;
    uint256 public lastDepositTime;
    uint256 public startDepositTime;
    uint256 public dailyYield;

    // threshold for accumulated matic need to be fulfilled before complete.
    uint256 public thresholdYield;
    bool public isRunning;

    uint256 multiplier;
    uint256 percentMultiplier;

    mapping(address => uint256) public stakes;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event OwnerDeposited(address indexed owner, uint256 amount);
    event StakePaused();
    event StakeContinued();

    constructor(address _stakeToken, address _yieldToken, uint256 _thresholdYield) {
        owner = msg.sender;
        stakeToken = _stakeToken;
        yieldToken = _yieldToken;
        lastDepositTime = block.timestamp;
        startDepositTime = 0;
        thresholdYield = _thresholdYield;
        isRunning = true;
        multiplier = 1e3;
        percentMultiplier = 100;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyWhenRunning() {
        require(isRunning, "Pool Yield Not running");
        _;
    }

    // For disable user to do new staking
    function pauseStaking() external onlyOwner {
        isRunning = false;
        emit StakePaused();
    }

    // For enable user to do new staking
    function unpauseStaking() external onlyOwner {
        isRunning = true;
        emit StakeContinued();
    }

    function deposit(uint256 amount) external onlyOwner nonReentrant {
        IERC20 yToken = IERC20(yieldToken);

        require(yToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        if (startDepositTime == 0) {
            startDepositTime = block.timestamp;
        }

        ownerDeposit += amount;
        lastDepositTime = block.timestamp;

        emit OwnerDeposited(msg.sender, amount);
    }

    function stake(uint256 amount) external nonReentrant onlyWhenRunning {
        require(totalStaked < thresholdYield, "exceed maximum");

        IERC20 sToken = IERC20(stakeToken);
        
        require(sToken.transferFrom(msg.sender, address(this), amount), "Stake transfer failed");

        stakes[msg.sender] += amount;

        totalStaked += amount;

        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external nonReentrant {

        require(stakes[msg.sender] >= amount, "Insufficient stake amount");

        IERC20 sToken = IERC20(stakeToken);
        IERC20 yToken = IERC20(yieldToken);

        uint256 percentageUserShare = amount * percentMultiplier * multiplier / totalStaked;

        uint256 reward = ownerDeposit * percentageUserShare / (percentMultiplier * multiplier);

        require(yToken.balanceOf(address(this)) >= reward, "Insufficient reward tokens");

        require(sToken.transfer(msg.sender, amount), "Unstake transfer failed");
        require(yToken.transfer(msg.sender, reward), "Reward transfer failed");

        stakes[msg.sender] -= amount;
        totalStaked -= amount;
        ownerDeposit -= reward;

        emit Unstaked(msg.sender, amount);
    }

    function getYieldAPR() external view returns (uint256) {
        if (startDepositTime == 0) {
            return 0;
        }
        uint256 lengthYield = block.timestamp - startDepositTime;
        uint256 lengthYieldInDays = lengthYield / 1 days;
        if (lengthYieldInDays == 0) {
            return ownerDeposit * 365;
        }
        return ownerDeposit / lengthYieldInDays * 365;
    }
}