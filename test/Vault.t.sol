// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {WETH9} from "./mocks/WETH9.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract VaultTest is Test {
    Vault public vault;
    WETH9 public weth;
    MockERC20 public mockToken;

    address public user1 = address(1);

    function setUp() public {
        mockToken = new MockERC20();
        weth = new WETH9();
        vault = new Vault(address(weth));

        vm.deal(user1, 5 ether);
        mockToken.mint(user1, 1000);
    }

    function testdepositEth() public {
        vm.prank(user1);
        vault.depositETH{value: 0.2 ether}();
    }

    function testwithdrawEth() public {
        vm.startPrank(user1);

        vault.depositETH{value: 0.2 ether}();

        vault.withdrawETH(0.1 ether);
    }

    function testwrapEth() public {
        vm.startPrank(user1);
        vault.depositETH{value: 0.2 ether}();
        vault.wrapETH(0.1 ether);
    }

    function testunwrapEth() public {
        vm.startPrank(user1);
        vault.depositETH{value: 0.2 ether}();
        vault.wrapETH(0.1 ether);

        vault.unwrapETH(0.1 ether);
    }

    function testdepositERC20() public {
        vm.startPrank(user1);
        mockToken.approve(address(vault), 10000000);
        vault.depositToken(address(mockToken), 100);
    }

    function testwithdrawERC20() public {
        vm.startPrank(user1);
        mockToken.approve(address(vault), 10000000);
        vault.depositToken(address(mockToken), 100);

        vault.withdrawToken(address(mockToken), 10);
    }
}
