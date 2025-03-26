// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {RebaseToken} from "../src/RebaseToken.sol";
import {IRebaseToken} from "../src/interfaces/IRebaseToken.sol";

contract RebaseTokenTest is Test {
    Vault public vault;
    RebaseToken public rebaseToken;

    address public owner = makeAddr("owner");
    address public user = makeAddr("user");

    function setUp() public {
        vm.startPrank(owner);
        rebaseToken = new RebaseToken("RebaseToken", "RBT");
        vault = new Vault(IRebaseToken(address(rebaseToken)));
        rebaseToken.grantMintAndBurnRole(address(vault));
        // solhint-disable-next-line
        (bool success,) = payable(address(vault)).call{value: 1e18}("");
        vm.stopPrank();
    }

    function addRewardsToVault(uint256 amount) public {
        vm.deal(owner, amount);
        vm.prank(owner);
        (bool success,) = payable(address(vault)).call{value: amount}("");
        require(success, "Failed to add rewards to vault");
    }

    function testMint() public {
        vm.startPrank(address(vault));
        rebaseToken.mint(address(vault), 1000000000000000000);
        vm.stopPrank();
    }

    /**
     * This is a fuzz test
     */
    function testDepositLinear(uint256 amount) public {
        // vm.assume(amount > 1e4); // if this cannot be reached we just skip the test
        amount = bound(amount, 1e5, type(uint96).max); // This will just make the amount in the fuzzed range and do the test
        // 1. deposit
        vm.startPrank(user);
        vm.deal(user, amount); // get him some eth for free
        vault.deposit{value: amount}();
        uint256 startBalance = rebaseToken.balanceOf(user);
        vm.stopPrank();
        // 2. check our rebase token balance
        console.log("startBalance", startBalance);
        assertEq(startBalance, amount);
        // 3. warp the time and check the balance again
        vm.warp(block.timestamp + 1 hours);
        uint256 middleBalance = rebaseToken.balanceOf(user);
        console.log("middleBalance", middleBalance);
        assertGt(middleBalance, amount);
        // 4. warp the time and check the balance again
        vm.warp(block.timestamp + 1 hours);
        uint256 endBalance = rebaseToken.balanceOf(user);
        console.log("endBalance", endBalance);
        assertGt(endBalance, middleBalance);
        assertApproxEqAbs(middleBalance - startBalance, endBalance - middleBalance, 1);
    }

    function testRedeemStraightAway(uint256 amount) public {
        amount = bound(amount, 1e5, type(uint96).max);
        vm.startPrank(user);
        vm.deal(user, amount);
        vault.deposit{value: amount}();
        assertEq(rebaseToken.balanceOf(user), amount);
        vault.redeem(type(uint256).max);
        assertEq(rebaseToken.balanceOf(user), 0);
        vm.stopPrank();
    }

    function testRedeemAfterTimePassed(uint256 time, uint256 depositAmount) public {
        time = bound(time, 1 hours, 19000 days);
        depositAmount = bound(depositAmount, 1e5, type(uint96).max);
        vm.deal(user, depositAmount);
        vm.prank(user);
        vault.deposit{value: depositAmount}();
        vm.warp(block.timestamp + time);
        uint256 balanceAfterTimePassed = rebaseToken.balanceOf(user);
        addRewardsToVault(balanceAfterTimePassed - depositAmount);
        vm.prank(user);
        vault.redeem(type(uint256).max);
        assertEq(rebaseToken.balanceOf(user), 0);
        assertEq(balanceAfterTimePassed, address(user).balance);
        assertGt(balanceAfterTimePassed, depositAmount);
    }

    function testTransfer(uint256 amount, uint256 amountToSend) public {
        amount = bound(amount, 1e5 + 1e5, type(uint96).max);
        amountToSend = bound(amountToSend, 1e5, amount - 1e5);

        // 1. deposit
        vm.startPrank(user);
        vm.deal(user, amount);
        vault.deposit{value: amount}();
        vm.stopPrank();

        address user2 = makeAddr("user2");
        vm.startPrank(user);
        rebaseToken.transfer(user2, amountToSend);
        vm.stopPrank();

        // 2. check the balances
        assertEq(rebaseToken.balanceOf(user), amount - amountToSend);
        assertEq(rebaseToken.balanceOf(user2), amountToSend);
    }
}
