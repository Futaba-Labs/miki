// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { ITokenPool } from "./interfaces/ITokenPool.sol";
import { L2AssetManagerStorage } from "./L2AssetManagerStorage.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

/**
 * @title L2AssetManager
 * @notice This contract manages the deposits and withdrawals of the user
 */
contract L2AssetManager is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, L2AssetManagerStorage {
    using SafeERC20 for IERC20;
    /* ----------------------------- Modifier -------------------------------- */

    modifier onlyWhitelistedTokenPool() {
        _checkTokenPoolIsWhitelisted(msg.sender);
        _;
    }
    /* ----------------------------- External Functions -------------------------------- */
    /**
     * @notice Initialize the contract
     * @param initialOwner The initial owner of the contract
     */

    function initialize(address initialOwner) external initializer {
        __Ownable_init(initialOwner);
        __ReentrancyGuard_init();
    }

    /**
     * @notice Deposit the token to the token pool
     * @param token The token to deposit
     * @param tokenPool The token pool to deposit to
     * @param amount The amount to deposit
     */
    function deposit(address token, address tokenPool, uint256 amount) external nonReentrant {
        _checkTokenPoolIsWhitelisted(tokenPool);
        IERC20(token).safeTransferFrom(msg.sender, address(tokenPool), amount);
        ITokenPool(tokenPool).deposit(amount);
        ITokenPool(tokenPool).addBatches(msg.sender, amount);
        _addDeposits(tokenPool, msg.sender, amount);
    }

    /**
     * @notice Deposit the ETH to the token pool
     * @param amount The amount to deposit
     */
    function depositETH(uint256 amount) external payable {
        ITokenPool(nativeTokenPool).deposit{ value: amount }(amount);
        ITokenPool(nativeTokenPool).addBatches(msg.sender, amount);
        _addDeposits(nativeTokenPool, msg.sender, amount);
    }

    /**
     * @notice Withdraw the token from the token pool
     * @param tokenPool The token pool to withdraw from
     * @param amount The amount to withdraw
     * @param recipient The recipient of the token
     */
    function withdraw(address tokenPool, uint256 amount, address recipient) external {
        _checkTokenPoolIsWhitelisted(tokenPool);
        ITokenPool(tokenPool).withdraw(recipient, amount);
        _removeDeposits(tokenPool, msg.sender, amount);
        emit Withdraw(tokenPool, msg.sender, recipient, amount);
    }

    /**
     * @notice Withdraw the ETH from the token pool
     * @param amount The amount to withdraw
     * @param recipient The recipient of the token
     */
    function withdrawETH(uint256 amount, address recipient) external {
        ITokenPool(nativeTokenPool).withdraw(recipient, amount);
        _removeDeposits(nativeTokenPool, msg.sender, amount);
        emit Withdraw(nativeTokenPool, msg.sender, recipient, amount);
    }

    /**
     * @notice Add deposits to the user
     * @param tokenPool The token pool to deposit to
     * @param user The user to add the deposits to
     * @param amount The amount to add
     */
    function addDeposits(address tokenPool, address user, uint256 amount) external onlyWhitelistedTokenPool {
        _addDeposits(tokenPool, user, amount);
    }

    /**
     * @notice Remove deposits from the user
     * @param tokenPool The token pool to remove from
     * @param user The user to remove the deposits from
     * @param amount The amount to remove
     */
    function removeDeposits(address tokenPool, address user, uint256 amount) external onlyWhitelistedTokenPool {
        _removeDeposits(tokenPool, user, amount);
    }

    /**
     * @notice Set the token pool whitelists
     * @param tokenPools The token pool addresses
     * @param isWhitelisted The whitelist status
     */
    function setTokenPoolWhitelists(address[] calldata tokenPools, bool[] calldata isWhitelisted) external onlyOwner {
        uint256 length = tokenPools.length;
        if (length != isWhitelisted.length) revert ArrayLengthMismatch();

        for (uint256 i; i < length;) {
            tokenPoolisWhitelisted[tokenPools[i]] = isWhitelisted[i];
            emit TokenPoolWhitelistUpdated(tokenPools[i], isWhitelisted[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Get the token pool whitelist status
     * @param tokenPool The token pool address
     * @return The whitelist status
     */
    function getTokenPoolWhitelist(address tokenPool) external view returns (bool) {
        return tokenPoolisWhitelisted[tokenPool];
    }

    /**
     * @notice Set the native token pool
     * @param tokenPool The token pool address
     */
    function setNativeTokenPool(address tokenPool) external onlyOwner {
        nativeTokenPool = tokenPool;
        tokenPoolisWhitelisted[tokenPool] = true;
    }

    /**
     * @notice Get the native token pool
     * @return The native token pool address
     */
    function getNativeTokenPool() external view returns (address) {
        return nativeTokenPool;
    }

    /**
     * @notice Get the deposit for the user
     * @param tokenPool The token pool address
     * @param user The user address
     * @return The deposit amount
     */
    function getDeposit(address tokenPool, address user) external view returns (uint256) {
        return balances[tokenPool][user];
    }

    /**
     * @notice Get the deposits for the user
     * @param user The user address
     * @return The token pool addresses and the amounts
     */
    function getDeposits(address user) external view returns (address[] memory, uint256[] memory) {
        uint256 length = userTokenPools[user].length;
        uint256[] memory amounts = new uint256[](length);

        for (uint256 i; i < length;) {
            amounts[i] = balances[userTokenPools[user][i]][user];
            unchecked {
                ++i;
            }
        }

        return (userTokenPools[user], amounts);
    }

    /* ----------------------------- Internal Functions -------------------------------- */

    /**
     * @notice Add deposits to the user
     * @param user The user address
     * @param amount The amount to add
     */
    function _addDeposits(address tokenPool, address user, uint256 amount) internal {
        if (balances[tokenPool][user] == 0) {
            userTokenPools[user].push(tokenPool);
        }
        balances[tokenPool][user] += amount;
        emit AddDeposits(tokenPool, user, amount);
    }

    /**
     * @notice Remove deposits from the user
     * @param user The user address
     * @param amount The amount to remove
     */
    function _removeDeposits(address tokenPool, address user, uint256 amount) internal {
        uint256 currentBalance = balances[tokenPool][user];
        if (currentBalance < amount) revert AmountLessThanZero();
        if (currentBalance == amount) {
            for (uint256 i; i < userTokenPools[user].length; i++) {
                if (userTokenPools[user][i] == tokenPool) {
                    userTokenPools[user][i] = userTokenPools[user][userTokenPools[user].length - 1];
                    userTokenPools[user].pop();
                    break;
                }
            }
        }
        balances[tokenPool][user] -= amount;
        emit RemoveDeposits(tokenPool, user, amount);
    }

    /**
     * @notice Check if the token pool is whitelisted
     * @param tokenPool The token pool address to check
     */
    function _checkTokenPoolIsWhitelisted(address tokenPool) internal view {
        if (!tokenPoolisWhitelisted[tokenPool]) {
            revert NotWhitelistedTokenPool();
        }
    }
}
