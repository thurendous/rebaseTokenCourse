// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

error RebaseToken__InterestRateCannotBeDecreased(uint256, uint256);

/**
 * @title RebaseToken
 * @notice A token that rebases its supply over time
 * @author Mark Wu
 * @notice This contract is a cross-chain token that incentivises users to deposit into a vault
 * @notice The interest rate in the smart contract can only decrease over time
 * @notice Each user will have their own interest rate that is the global interest rate at the time of deposit
 * @dev the `totalSupply` function is left as erc20's function, so it will only return the principle balance of the user. It will not inculde the interest that has accrued.
 */
contract RebaseToken is ERC20, Ownable, AccessControl {
    uint256 private s_interestRate = (1 * PRECISION_FACTOR) / 1e8;
    bytes32 private constant MINT_AND_BURN_ROLE = keccak256("MINT_AND_BURN_ROLE");

    mapping(address => uint256) private s_userInterestRate;
    mapping(address => uint256) private s_userLastUpdatedTimestamp;

    uint256 private constant PRECISION_FACTOR = 1e18;

    event InterestRateSet(uint256 newInterestRate);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) Ownable(msg.sender) {}

    function grantMintAndBurnRole(address _user) external onlyOwner {
        _grantRole(MINT_AND_BURN_ROLE, _user);
    }

    function setInterestRate(uint256 _newInterestRate) external onlyOwner {
        if (_newInterestRate < s_interestRate) {
            revert RebaseToken__InterestRateCannotBeDecreased(_newInterestRate, s_interestRate);
        }
        // set the interest rate
        s_interestRate = _newInterestRate;
        emit InterestRateSet(_newInterestRate);
    }

    /**
     * @notice Mint the user tokens when they deposit into the vault
     * @param _to The address of the user to mint the tokens to
     * @param _amount The amount of tokens to mint
     */
    function mint(address _to, uint256 _amount) external onlyRole(MINT_AND_BURN_ROLE) {
        _mintAccruedInterest(_to); // This is for minting the previous interest rate part for the user
        s_userInterestRate[_to] = s_interestRate;
        _mint(_to, _amount);
    }

    /**
     * @notice Mint the user tokens since the last time he interacted with the contract(e.g. mint, burn, transfer)
     * @param _to The address of the user to mint the tokens to
     */
    function _mintAccruedInterest(address _to) internal {
        // find the current balance of rebase tokens that have been minted to the user -> principleBalance
        uint256 previousPrincipleBalance = super.balanceOf(_to);

        // calculate their current balance including any interest -> balanceOf
        uint256 currentBalance = balanceOf(_to);

        // calculate the number of tokens needed to be minted to the user (2) - (1)
        uint256 balanceIncreased = currentBalance - previousPrincipleBalance;
        // call mint to mint the tokens to the user
        // set the users last updated timestamp
        // uint256 timeElapsed = block.timestamp - s_userLastUpdatedTimestamp[_to];
        // uint256 linearInterest = (PRECISION_FACTOR + s_userInterestRate[_to] * timeElapsed / 1e18) * principleBalance / PRECISION_FACTOR;
        // uint256 amountToMint = linearInterest - principleBalance;
        s_userLastUpdatedTimestamp[_to] = block.timestamp;
        _mint(_to, balanceIncreased);
    }

    /**
     * @notice Calculate the balance of the user including any interest that has accumulated since the last update
     * (principle balance) + some interest that has accrued
     * @param _user The address of the user to calculate the balance of
     * @return The balance of the user including any interest that has accumulated since the last update
     */
    function balanceOf(address _user) public view override returns (uint256) {
        // get the current principle balance of the user (the number of tokens that have actually been minted to the user)
        // multiply the principle balance by the interest that has accumulated in the time since the last update
        return super.balanceOf(_user) * _calculateInterestRateSinceLastUpdate(_user) / PRECISION_FACTOR;
    }

    function _calculateInterestRateSinceLastUpdate(address _user) internal view returns (uint256 linearInterest) {
        // we need to calculate the interest that has accumulated since the last update
        // this is going to be linear growth with time
        // 1. calculate the time since the last update
        // 2. calculate the amount of linear growth
        // (principal amount) + (principal amount * user interest rate * time elapsed)
        // e.g. deposit amoutn = 10
        // interest rate 0.5 tokens per second
        // time elapsed = 2 seconds
        // 10 + (10 * 0.5 * 2) = 20
        uint256 timeElapsed = block.timestamp - s_userLastUpdatedTimestamp[_user];
        linearInterest = (PRECISION_FACTOR + (s_userInterestRate[_user] * timeElapsed));
    }

    /**
     * @notice Burn the user tokens when they burn their tokens
     * @param _from The address of the user to burn the tokens from
     * @param _amount The amount of tokens to burn
     * @dev We need to also handle the dust amount which is the amount of tokens when the tx is going through. So the interest generated from it is called the `dust amount`.
     */
    function burn(address _from, uint256 _amount) external onlyRole(MINT_AND_BURN_ROLE) {
        // considering the dust amount of the tx. This is just a standard way to handle it in DeFi.
        // This can mitigate the dust issue.
        _mintAccruedInterest(_from);
        _burn(_from, _amount);
    }

    /**
     * @notice Transfer the tokens to the recipient
     * @param _recipient The address of the recipient
     * @param _amount The amount of tokens to transfer
     * @return bool
     * @notice The protocol is designed to use the recipient's interest rate at the time of transfer if the recipient has a interest rate.
     * On the other hand, if the recipient has no interest rate, the protocol will use the global interest rate at the time of transfer.
     */
    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        _mintAccruedInterest(msg.sender);
        _mintAccruedInterest(_recipient);
        if (_amount == type(uint256).max) {
            _amount = balanceOf(msg.sender);
        }
        if (balanceOf(_recipient) == 0) {
            s_userInterestRate[_recipient] = s_interestRate;
        }
        return super.transfer(_recipient, _amount);
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        _mintAccruedInterest(_sender);
        _mintAccruedInterest(_recipient);
        if (_amount == type(uint256).max) {
            _amount = balanceOf(_sender);
        }
        if (balanceOf(_recipient) == 0) {
            s_userInterestRate[_recipient] = s_interestRate;
        }
        return super.transferFrom(_sender, _recipient, _amount);
    }

    /**
     * @notice
     */
    function getUserInterestRate(address user) external view returns (uint256) {
        return s_userInterestRate[user];
    }

    /**
     * @notice Get the principle balance of the user
     * @param _user The address of the user to get the principle balance of
     * @return The principle balance of the user
     * @notice This principle balance is the balance of the user that has been minted to them. It does not include the interest that has accrued since the last time the user interacted with the protocol.
     */
    function principleBalanceOf(address _user) external view returns (uint256) {
        return super.balanceOf(_user);
    }

    /**
     * @notice Get the current interest rate. This interest rate is the current interest rate of the protocol. Any future depositers will use this interest rate to calculate the interest.
     * @return The current interest rate
     */
    function getInterestRate() external view returns (uint256) {
        return s_interestRate;
    }
}
