// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.17;
import "./interfaces/IYCBYield.sol";
import "./utils/SafeERC20.sol";

contract YCBYield is IYCBYield {
    using SafeERC20 for IERC20; 

    uint yieldRate = 15; // 0.15% default minimum yield
    uint depositFeeRate = 100; // 1% deposit fee
    uint totalPercentage = 10000; // 100%



    address centralWallet;
     
    /**
     * triggered by Factory YIeld
     */
    function distributeYield(
        uint _amount
    ) external returns (uint _amountLeft) {

    }
    /**
     * triggered by IYCBStorage owner
     */
    function depositYield(
        address _userPath,
        address _token,
        uint _amount
    ) external returns (uint _totalDeposit) {
        require(_amount > 0, "Amount must be greater than 0");
        require(
            IERC20(_token).allowance(_userPath, address(this)) >=
                _amount,
            "Insufficient allowance"
        );

        uint256 depositFee = (_amount * depositFeeRate) / totalPercentage;
        uint256 amountToDeposit = _amount - depositFee;
        IERC20(_token).safeTransferFrom(
            _userPath,
            address(this),
            _amount
        );

        IERC20(_token).safeTransfer(centralWallet, depositFee);

        _totalDeposit = amountToDeposit;
    }
    /**
     * trigger by owner
     */
    function emergencyTransfer(
        address _storagePath,
        address _token,
        uint _amount
    ) external {

    }
}