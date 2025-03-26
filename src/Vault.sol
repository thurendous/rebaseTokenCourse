// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IRebaseToken} from "./interfaces/IRebaseToken.sol";

error Vault__RedeemFailed();

/// @notice maybe we should set a max deposit amount to limit the amount of rewards we can set up for the users in case it crosses the limit.
contract Vault {
    // we need to pass the token address to the constructor
    // create a deposit function that deposits the token into the vault
    // create a redeem function that redeems the token from the vault
    // create a way to add rewards to the vault
    IRebaseToken private immutable i_rebaseToken;

    event Deposit(address indexed user, uint256 amount);
    event Redeem(address indexed user, uint256 amount);
    event AddRewards(address indexed user, uint256 amount);

    constructor(IRebaseToken _rebaseToken) {
        i_rebaseToken = _rebaseToken;
    }

    receive() external payable {}

    /**
     * @notice Deposit ETH into the vault and mint tokens to the user
     */
    function deposit() external payable {
        // 1. we need to use the amount of ETH the user has sent to mint tokens to the user
        i_rebaseToken.mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice Redeem tokens from the vault and send ETH to the user
     * @param _amount The amount of tokens to redeem
     */
    function redeem(uint256 _amount) external {
        if (_amount == type(uint256).max) {
            _amount = i_rebaseToken.balanceOf(msg.sender);
        }
        // 1. burn the tokens from the user
        i_rebaseToken.burn(msg.sender, _amount);
        // 2. we need to send the user ETH
        (bool success,) = payable(msg.sender).call{value: _amount}("");
        if (!success) revert Vault__RedeemFailed();
        emit Redeem(msg.sender, _amount);
    }

    /**
     * @notice Add rewards to the vault
     * @param _amount The amount of rewards to add
     */
    function addRewards(uint256 _amount) external {
        i_rebaseToken.setInterestRate(_amount);
    }

    function getRebaseTokenAddress() external view returns (address) {
        return address(i_rebaseToken);
    }
}
