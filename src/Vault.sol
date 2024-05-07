// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {IWETH} from "../interface/IWETH.sol";
import {ReentrancyGuard} from "@openzeppelin/utils/ReentrancyGuard.sol";

contract Vault is ReentrancyGuard {
    address public immutable WETH;

    uint256 totalETH;
    uint256 totalWETH;

    mapping(address => uint256) ethBalance;
    mapping(address => uint256) wethBalance;
    mapping(address => mapping(address => uint256)) tokenBalances;

    event EthDeposited(uint256 depoisted);
    event EthWithdrawn(uint256 withdrawn);
    event EthWraped(uint256 amount);
    event EthUwraped(uint256 amount);
    event Erc20Deposited(address token, uint256 amount);
    event Erc20Withdrawn(address token, uint256 amount);

    constructor(address _weth) {
        WETH = _weth;
    }

    function depositETH() external payable {
        ethBalance[msg.sender] += msg.value;
        totalETH += msg.value;
        emit EthDeposited(msg.value);
    }

    function withdrawETH(uint256 amount) external {
        require(ethBalance[msg.sender] >= amount, "Insufficient ETH balance");
        ethBalance[msg.sender] -= amount;
        totalETH = totalETH - amount;
        (bool sent,) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send ETH");
        emit EthWithdrawn(amount);
    }

    function wrapETH(uint256 amount) external {
        require(ethBalance[msg.sender] >= amount, "Insufficient ETH balance");
        ethBalance[msg.sender] -= amount;
        IWETH(WETH).deposit{value: amount}();
        wethBalance[msg.sender] += amount;
        totalETH -= amount;
        totalWETH += amount;
        emit EthWraped(amount);
    }

    function unwrapETH(uint256 amount) external {
        require(wethBalance[msg.sender] >= amount, "Insufficient WETH balance");
        wethBalance[msg.sender] -= amount;
        IWETH(WETH).withdraw(amount);
        totalWETH -= amount;
        totalETH += amount;
        emit EthUwraped(amount);
    }

    function depositToken(address token, uint256 amount) nonReentrant external {
        require(amount > 0);
        uint256 currentBalance = IERC20(token).balanceOf(address(this));
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Transfer failed");
        require(currentBalance + amount == IERC20(token).balanceOf(address(this)));
        tokenBalances[token][msg.sender] += amount;
        emit Erc20Deposited(token, amount);
    }

    // Function to withdraw ERC20 tokens
    function withdrawToken(address token, uint256 amount) nonReentrant external {
        require(amount > 0);
        uint256 currentBalance = IERC20(token).balanceOf(address(this));
        require(tokenBalances[token][msg.sender] >= amount, "Insufficient token balance");
        tokenBalances[token][msg.sender] -= amount;
        require(IERC20(token).transfer(msg.sender, amount), "Transfer failed");
        require(currentBalance - amount == IERC20(token).balanceOf(address(this)));
        emit Erc20Withdrawn(token, amount);
    }

    receive() external payable {}
}
