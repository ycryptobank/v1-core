// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.17;
import "./interfaces/IYCBYieldFactory.sol";
import "./YCBYield.sol";
import "./utils/SafeERC20.sol";
import "./utils/ReentrancyGuard.sol";

contract YCBYieldFactory is IYCBYieldFactory, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address owner;

    mapping(uint256 => address) yieldList;
    address[] activeYield;
    address[] inactiveYield;

    uint256 campaignId;

    constructor() {
        owner = msg.sender;
    }

    function createYieldCampaign(
        address _tokenYield,
        address _tokenBonus,
        uint256 _yieldRate,
        uint256 _depositRate,
        uint256 _frozenPeriods
    ) external onlyOwner {
        address _yield = address(
            new YCBYield(
                owner,
                _tokenYield,
                _tokenBonus,
                _yieldRate,
                _depositRate,
                _frozenPeriods
            )
        );
        yieldList[campaignId] = _yield;
        activeYield.push(_yield);
        campaignId += 1;
    }

    function startYield(address _yieldPath) external onlyOwner {
        IYCBYield _yield = IYCBYield(_yieldPath);
        _yield.yieldStarting();
    }

    function completeYield(address _yieldPath, uint256 _amount)
        external
        onlyOwner
    {
        IYCBYield _yield = IYCBYield(_yieldPath);
        IERC20(_yield.getTokenYield()).safeTransferFrom(
            msg.sender,
            _yieldPath,
            _amount
        );
        _yield.yieldCompleted();
        inactiveYield.push(_yieldPath);
        removeActiveYield(_yieldPath);
    }

    function getActiveYields()
        external
        view
        returns (address[] memory _yields)
    {
        _yields = activeYield;
    }

    function getInActiveYields()
        external
        view
        returns (address[] memory _yields)
    {
        _yields = inactiveYield;
    }

    function distributeYield(
        address _yieldPath,
        uint256 _amount,
        uint256 _tokenDecimals
    ) external onlyOwner nonReentrant {
        IYCBYield _yield = IYCBYield(_yieldPath);
        _yield.distributeBonusYield(_amount, _tokenDecimals);
        IERC20(_yield.getTokenBonus()).safeTransferFrom(
            msg.sender,
            _yieldPath,
            _amount
        );
    }

    function popInActiveYield() public onlyOwner {
        inactiveYield.pop();
    }

    function removeActiveYield(address _yieldPath) private onlyOwner {
        uint i = 0;
        while ( i < activeYield.length ) {
            address _currentPath = activeYield[i];
            if (_currentPath == _yieldPath) {
                activeYield[i] = activeYield[activeYield.length - 1];
                activeYield.pop();
                i = activeYield.length;
            }
            i ++;
        }
    }

    modifier onlyOwner() {
        require((owner == msg.sender), "Ownable: Caller is not the Owner");
        _;
    }
}
