// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.17;
import './interfaces/IYCBStorage.sol';
import './interfaces/IYCBYield.sol';
import './utils/SafeERC20.sol';


contract YCBStorage is IYCBStorage {
    using SafeERC20 for IERC20;

    string private password;
    address yieldAddress;
    bool isActive;

    mapping (address => uint) depositedTokens;
    uint amountLocked;
    address owner;
    address factory;

    address tokenBonus;
    address tokenYield;

    constructor(string memory _password, address _yieldAddress, address _tokenBonus, address _tokenYield, address _owner) {
        password = _password;
        yieldAddress = _yieldAddress;
        owner = _owner;
        factory = msg.sender;
        isActive = true;
        tokenBonus = _tokenBonus;
        tokenYield = _tokenYield;
        amountLocked = 0;
    }

    function lockToYield(
        address _yieldPath,
        address _token,
        uint _amount,
        string memory _password
    ) external onlyOwner returns (uint _amountLocked) {
        require(getBalance(_token) >= _amount, "Balance not match to lock");
        require(keccak256(bytes(password)) == keccak256(bytes(_password)), "password incorrect");
        amountLocked = amountLocked + IYCBYield(_yieldPath).depositYield(msg.sender, _token, _amount);
        _amountLocked = amountLocked;
    }

    function withdrawFunds(
        string memory _password
    ) external onlyOwner {
        uint _amount = getBalance(tokenYield);
        require(_amount > 0, "no balance of this token");
        require(compare(password, _password), "password incorrect");
        IERC20(tokenYield).safeTransfer(msg.sender, _amount);
        isActive = false;
    }

    function withdrawBonus(
        string memory _password
    ) external onlyOwner {
        uint _amount = getBalance(tokenBonus);
        require(_amount > 0, "no balance of bonus");
        require(compare(password, _password), "password incorrect");
        IERC20(tokenBonus).safeTransfer(msg.sender, _amount);
    }

    function listDepositToken() external view returns (address[] memory tokens) {
        address[] memory _listToken = new address[](2);
        _listToken[0] = tokenYield;
        _listToken[1] = tokenBonus;
        tokens = _listToken;
    }

    function isActiveStorage() external view returns (bool _isActiveStorage) {
        _isActiveStorage = isActive;
    }

    modifier onlyOwner() {
		require((owner == msg.sender), "Ownable: Caller is not the Owner");
		_;
	}

    modifier onlyFactory() {
        require((factory == msg.sender), "Ownable: caller is not the factory");
        _;
    }

    function getBalance(
        address token
    ) public view returns (uint amount) {
        amount = IERC20(token).balanceOf(address(this));
    }

    function compare(string memory str1, string memory str2) public pure returns (bool) {
        if (bytes(str1).length != bytes(str2).length) {
            return false;
        }
        return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
    }
}