// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

/**
 * @title IL2AssetManager
 * @notice This contract is the interface for the L2AssetManager contract
 */
interface IL2AssetManager {
    /* ----------------------------- Events -------------------------------- */

    /// @notice Add deposits to the user
    event AddDeposits(address tokenPool, address user, uint256 amount);

    /// @notice Remove deposits from the user
    event RemoveDeposits(address tokenPool, address user, uint256 amount);

    /// @notice Withdraw ETH from the user
    event Withdraw(address tokenPool, address user, address recipient, uint256 amount);

    /// @notice Update the token pool whitelist status
    event TokenPoolWhitelistUpdated(address tokenPool, bool isWhitelisted);

    /* ----------------------------- Erorrs -------------------------------- */

    /// @notice The array lengths do not match
    error ArrayLengthMismatch();

    /// @notice The amount is less than zero
    error AmountLessThanZero();

    /// @notice The token pool is not whitelisted
    error NotWhitelistedTokenPool();

    /* ----------------------------- Functions -------------------------------- */

    /**
     * @notice Deposit the token to the token pool
     * @param token The token to deposit
     * @param tokenPool The token pool to deposit to
     * @param amount The amount to deposit
     */
    function deposit(address token, address tokenPool, uint256 amount) external;

    /**
     * @notice Deposit the ETH to the token pool
     * @param amount The amount to deposit
     */
    function depositETH(uint256 amount) external payable;

    /**
     * @notice Withdraw the token from the token pool
     * @param token The token to withdraw
     * @param amount The amount to withdraw
     * @param recipient The recipient of the token
     */
    function withdraw(address token, uint256 amount, address recipient) external;

    /**
     * @notice Withdraw the ETH from the token pool
     * @param amount The amount to withdraw
     * @param recipient The recipient of the token
     */
    function withdrawETH(uint256 amount, address recipient) external;

    /**
     * @notice Add deposits to the user
     * @param tokenPool The token pool to deposit to
     * @param user The user to add the deposits to
     * @param amount The amount to add
     */
    function addDeposits(address tokenPool, address user, uint256 amount) external;

    /**
     * @notice Remove deposits from the user
     * @param tokenPool The token pool to remove from
     * @param user The user to remove the deposits from
     * @param amount The amount to remove
     */
    function removeDeposits(address tokenPool, address user, uint256 amount) external;

    /**
     * @notice Update the token pool whitelist status
     * @param tokenPools The token pools to update
     * @param isWhitelisted The new whitelist status
     */
    function setTokenPoolWhitelists(address[] calldata tokenPools, bool[] calldata isWhitelisted) external;

    /**
     * @notice Get the token pool whitelist status
     * @param tokenPool The token pool to get the whitelist status for
     * @return The whitelist status
     */
    function getTokenPoolWhitelist(address tokenPool) external view returns (bool);

    /**
     * @notice Get the deposit for the user
     * @param tokenPool The token pool address
     * @param user The user address
     * @return The deposit amount
     */
    function getDeposit(address tokenPool, address user) external view returns (uint256);

    /**
     * @notice Get the deposits for the user
     * @param user The user address
     * @return The token pool addresses
     * @return The deposit amounts
     */
    function getDeposits(address user) external view returns (address[] memory, uint256[] memory);

    /**
     * @notice Set the native token pool
     * @param tokenPool The token pool address
     */
    function setNativeTokenPool(address tokenPool) external;

    /**
     * @notice Get the native token pool
     * @return The token pool address
     */
    function getNativeTokenPool() external view returns (address);
}
