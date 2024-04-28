// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

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

    function deposit(address token, address tokenPool, uint256 amount) external;
    function depositETH(uint256 amount) external payable;
    function withdraw(address token, uint256 amount, address recipient) external;
    function withdrawETH(uint256 amount, address recipient) external;
    function addDeposits(address tokenPool, address user, uint256 amount) external;
    function removeDeposits(address tokenPool, address user, uint256 amount) external;
    function setTokenPoolWhitelists(address[] calldata tokenPools, bool[] calldata isWhitelisted) external;
    function getTokenPoolWhitelist(address tokenPool) external view returns (bool);
    function getDeposit(address tokenPool, address user) external view returns (uint256);
    function getDeposits(address user) external view returns (address[] memory, uint256[] memory);
    function setNativeTokenPool(address tokenPool) external;
    function getNativeTokenPool() external view returns (address);
}
