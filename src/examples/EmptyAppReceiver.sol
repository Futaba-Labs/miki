// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { IMikiAppReceiver } from "../interfaces/IMikiAppReceiver.sol";

/**
 * @title EmptyAppReceiver
 * @notice This contract is used to mint NFTs from Miki
 */
contract EmptyAppReceiver is IMikiAppReceiver {
    /* ----------------------------- Storage -------------------------------- */
    /// @notice The MikiReceiver address
    address public mikiReceiver;

    /* ----------------------------- Events -------------------------------- */
    event MikiReceive(uint256 srcChainId, address srcAddress, address token, uint256 amount, bytes message);
    event MikiReceiveMsg(uint256 srcChainId, address srcAddress, bytes message);

    /* ----------------------------- Errors -------------------------------- */
    /// @notice This error is emitted when the sender is not the MikiReceiver
    error NotMikiReceiver();

    /* ----------------------------- Constructor ----------------------------- */
    /**
     * @notice This constructor is used to initialize the contract
     * @param _mikiReceiver The MikiReceiver address
     */
    constructor(address _mikiReceiver) {
        mikiReceiver = _mikiReceiver;
    }

    /* ----------------------------- Modifiers ----------------------------- */
    modifier onlyMikiReceiver() {
        if (msg.sender != mikiReceiver) revert NotMikiReceiver();
        _;
    }

    /* ----------------------------- Functions ----------------------------- */
    /**
     * @notice This function is used to receive a message and token from Miki and mint NFT
     * @param token The token address
     * @param amount The amount of the token
     * @param message The message
     */
    function mikiReceive(
        uint256 srcChainId,
        address srcAddress,
        address token,
        uint256 amount,
        bytes calldata message
    )
        external
        payable
        onlyMikiReceiver
    {
        emit MikiReceive(srcChainId, srcAddress, token, amount, message);
    }

    /**
     * @notice This function is used to receive a message from Miki and mint NFT
     * @param message The message
     */
    function mikiReceiveMsg(
        uint256 srcChainId,
        address srcAddress,
        bytes calldata message
    )
        external
        payable
        onlyMikiReceiver
    {
        emit MikiReceiveMsg(srcChainId, srcAddress, message);
    }

    fallback() external payable { }

    receive() external payable { }
}
