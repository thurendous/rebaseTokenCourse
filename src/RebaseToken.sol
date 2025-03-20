// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

error RebaseToken__InterestRateCannotBeIncreased(uint256, uint256);

/**
 * @title RebaseToken
 * @notice A token that rebases its supply over time
 * @author Mark Wu
 * @notice This contract is a cross-chain token that incentivises users to deposit into a vault
 * @notice The interest rate in the smart contract can only decrease over time
 * @notice Each user will have their own interest rate that is the global interest rate at the time of deposit
 */
contract RebaseToken is ERC20 {

    uint256 private s_interestRate = 5e10;

    mapping(address => uint256) private s_userInterestRate;

    event InterestRateSet(uint256 newInterestRate);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
    }
    

    function setInterestRate(uint256 _newInterestRate) external {
        if (_newInterestRate > s_interestRate) {
            revert RebaseToken__InterestRateCannotBeIncreased(_newInterestRate, s_interestRate);
        }
        // set the interest rate
        s_interestRate = _newInterestRate;
        emit InterestRateSet(_newInterestRate);
    }

    function mint(address _to, uint256 _amount) external {
        _mintAccruedInterest(_to); // This is for minting the previous interest rate part for the user
        s_userInterestRate[_to] = s_interestRate;
        _mint(_to, _amount);
    }

    function _mintAccruedInterest(address _to) internal {
        // find the current balance of rebase tokens that have been minted to the user -> principleBalance

        // calculate their current balance including any interest -> balanceOf
        // calculate the number of tokens needed to be minted to the user (2) - (1)
        // call mint to mint the tokens to the user
    }

    /**
    * @notice 
     */
    function getUserInterestRate(address user) external view returns (uint256) {
        return s_userInterestRate[user];
    }
}
