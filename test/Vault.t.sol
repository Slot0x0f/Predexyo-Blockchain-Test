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

        vm.deal(user1, 20 ether);
        mockToken.mint(user1, 1000);
    }

    function testdepositEth(uint256 ethAmount) public {
        uint256 input = bound(ethAmount, 1 ether, 4 ether);
        vm.prank(user1);
        vault.depositETH{value: input}();
    }

    function testwithdrawEth(uint256 ethAmount) public {
        uint256 input = bound(ethAmount, 1 ether, 4 ether);
        vm.startPrank(user1);
        vault.depositETH{value: input}();
        vault.withdrawETH(input);
    }

    function testwrapEth(uint256 ethAmount) public {
        uint256 input = bound(ethAmount, 1 ether, 4 ether);
        vm.startPrank(user1);
        vault.depositETH{value: input}();
        vault.wrapETH(input);
    }

    function testunwrapEth(uint256 ethAmount) public {
        uint256 input = bound(ethAmount, 1 ether, 4 ether);
        vm.startPrank(user1);
        vault.depositETH{value: input}();
        vault.wrapETH(input);

        vault.unwrapETH(input);
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
