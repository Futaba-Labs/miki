// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

interface IL2AssetManager {
    /* ----------------------------- Events -------------------------------- */

    /// @notice Add deposits to the user
    event AddDeposits(address tokenPool, address user, uint256 amount);

    /// @notice Remove deposits from the user
    event RemoveDeposits(address tokenPool, address user, uint256 amount);

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

    function deposit(address token, uint256 amount) external;
    function depositETH(uint256 amount) external;
    function withdraw(address token, uint256 amount, address recipient) external;
    function withdrawETH(uint256 amount, address recipient) external;
    function setTokenPoolWhitelists(address[] calldata tokenPools, bool[] calldata isWhitelisted) external;
    function getTokenPoolWhitelist(address tokenPool) external view returns (bool);
}
