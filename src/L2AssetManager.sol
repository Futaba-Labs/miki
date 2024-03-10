// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { L2AssetManagerStorage } from "./L2AssetManagerStorage.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract L2AssetManager is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, L2AssetManagerStorage {
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

    function deposit(address tokenPool, uint256 amount) external {
        // TODO: Implement deposit
    }

    function depositETH(uint256 amount) external {
        // TODO: Implement depositETH
    }

    function withdraw(address token, uint256 amount, address recipient) external {
        // TODO: Implement withdraw
    }
    function withdrawETH(uint256 amount, address recipient) external {
        // TODO: Implement withdrawETH
    }

    /**
     * @notice Set the token pool whitelists
     * @param tokenPools The token pool addresses
     * @param isWhitelisted The whitelist status
     */
    function setTokenPoolWhitelists(address[] calldata tokenPools, bool[] calldata isWhitelisted) external {
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

    /* ----------------------------- Internal Functions -------------------------------- */

    /**
     * @notice Add deposits to the user
     * @param user The user address
     * @param amount The amount to add
     */
    function _addDeposits(address user, uint256 amount) external {
        address tokenPool = msg.sender;
        balances[tokenPool][user] += amount;
        emit AddDeposits(tokenPool, user, amount);
    }

    /**
     * @notice Remove deposits from the user
     * @param user The user address
     * @param amount The amount to remove
     */
    function _removeDeposits(address user, uint256 amount) external {
        address tokenPool = msg.sender;
        uint256 currentBalance = balances[tokenPool][user];
        if (currentBalance < amount) revert AmountLessThanZero();
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
