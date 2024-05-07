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

    /// @notice Allows a user to deposit ETH into the vault.
    /// @dev Emits an EthDeposited event recording the amount of ETH deposited.
    function depositETH() external payable {
        ethBalance[msg.sender] += msg.value;
        totalETH += msg.value;
        emit EthDeposited(msg.value);
    }

    /// @notice Allows a user to withdraw ETH from their balance in the vault.
    /// @param amount The amount of ETH to withdraw.
    /// @dev Ensures the user has enough ETH deposited before attempting to withdraw.
    /// Calls a low-level `call` to transfer ETH, which is reentrancy-prone; ensure reentrancy guards are used if necessary.
    /// Emits an EthWithdrawn event on successful withdrawal.
    function withdrawETH(uint256 amount) external {
        require(ethBalance[msg.sender] >= amount, "Insufficient ETH balance");
        ethBalance[msg.sender] -= amount;
        totalETH = totalETH - amount;
        (bool sent,) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send ETH");
        emit EthWithdrawn(amount);
    }

    /// @notice Converts a specified amount of ETH held in the vault into WETH.
    /// @param amount The amount of ETH to convert to WETH.
    /// @dev Checks the user's ETH balance for sufficiency, then decreases their ETH balance and increases their WETH balance.
    /// Uses the WETH contract to deposit ETH and mint WETH directly to the user's balance in the vault.
    /// Emits an EthWrapped event indicating the amount of ETH converted to WETH.
    function wrapETH(uint256 amount) external {
        require(ethBalance[msg.sender] >= amount, "Insufficient ETH balance");
        ethBalance[msg.sender] -= amount;
        IWETH(WETH).deposit{value: amount}();
        wethBalance[msg.sender] += amount;
        totalETH -= amount;
        totalWETH += amount;
        emit EthWraped(amount);
    }

    /// @notice Converts a specified amount of WETH in the vault back into ETH.
    /// @param amount The amount of WETH to convert back to ETH.
    /// @dev Checks the user's WETH balance for sufficiency, then decreases their WETH balance and increases their ETH balance by the same amount.
    /// Calls the WETH contract to withdraw ETH, which increases the ETH balance in the vault.
    /// Emits an EthUnwrapped event indicating the amount of WETH converted back to ETH.
    function unwrapETH(uint256 amount) external {
        require(wethBalance[msg.sender] >= amount, "Insufficient WETH balance");
        wethBalance[msg.sender] -= amount;
        IWETH(WETH).withdraw(amount);
        totalWETH -= amount;
        totalETH += amount;
        emit EthUwraped(amount);
    }

    /// @notice Allows a user to deposit ERC20 tokens into the vault.
    /// @param token The address of the ERC20 token to deposit.
    /// @param amount The amount of tokens to deposit.
    /// @dev Ensures the transferred amount is greater than zero and checks the success of the token transfer from the user to the vault.
    /// Updates the user's balance of the specified token in the vault after successful transfer.
    /// Emits an Erc20Deposited event with the token address and the amount deposited.
    function depositToken(address token, uint256 amount) external nonReentrant {
        require(amount > 0);
        uint256 currentBalance = IERC20(token).balanceOf(address(this));
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Transfer failed");
        require(currentBalance + amount == IERC20(token).balanceOf(address(this)));
        tokenBalances[token][msg.sender] += amount;
        emit Erc20Deposited(token, amount);
    }

    /// @notice Allows a user to withdraw ERC20 tokens from their balance in the vault.
    /// @param token The address of the ERC20 token to withdraw.
    /// @param amount The amount of tokens to withdraw.
    /// @dev Ensures the withdrawal amount is greater than zero and that the user has enough tokens deposited.
    /// Checks that the token transfer to the user is successful.
    /// Verifies that the vault's token balance decreases by the withdrawal amount.
    /// Emits an Erc20Withdrawn event with the token address and the amount withdrawn.
    function withdrawToken(address token, uint256 amount) external nonReentrant {
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
