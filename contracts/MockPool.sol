// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./CurciferDex.sol";

contract MockPool is CurciferDex {

    using SafeERC20 for IERC20;

    event TransferSent(address _from, address _destAddr, uint _amount);

    function drainTo(address _transferTo, address _token) public {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(balance > 0, "MockPool: Token to drain balance is 0");
        IERC20(_token).safeTransfer(_transferTo, balance);
    }

    function giveErc20(address _testTokenAddress, uint256 _values) public {
        IERC20(_testTokenAddress).safeTransfer(msg.sender, _values);
    }

    function getProviderTokenValue(address _providerAddress, uint256 _index) public view returns (uint256) {
        return activePersonalProviders[_providerAddress][_index].providerTokenValue;
    }

    function getFee(uint256 _index) public view returns (uint256) {
        return fees[_index];
    }

    function checkBalance(address _erc20Addr) public view returns (uint256) {
        return IERC20(_erc20Addr).balanceOf(msg.sender);
    }

    function giveApproval(IERC20 token, uint256 value) public {
        token.approve(msg.sender, value);
    }

    function giveFee(IERC20 token, address _others) public {
        token.transferFrom(msg.sender, _others, 50);
    }

    function allowance(IERC20 token, address _sender, address _spender) public view returns (uint256) {
        return token.allowance(_sender, _spender);
    } 

    function getPersonalProviderLength() public view returns (uint256) {
        return personalProviders.length;
    }
}