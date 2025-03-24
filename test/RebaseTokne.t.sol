// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {RebaseToken} from "../src/RebaseToken.sol";
import {IRebaseToken} from "../src/interfaces/IRebaseToken.sol";

contract RebaseTokenTest is Test {
    Vault public vault;
    RebaseToken public rebaseToken;

    function setUp() public {
        rebaseToken = new RebaseToken("RebaseToken", "RBT");
        vault = new Vault(IRebaseToken(address(rebaseToken)));
    }

    function test_Mint() public {
        vm.startPrank(address(vault));
        rebaseToken.mint(address(vault), 1000000000000000000);
        vm.stopPrank();
    }
}
