// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { IMikiReceiver } from "../interfaces/IMikiReceiver.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MikiRouterReceiver
 * @notice This contract is the receiver of the messages and ETH from the MikiRouter operated by Gelato
 */
contract MikiRouterReceiver is Ownable {
    /* ----------------------------- Storage -------------------------------- */

    /// @notice The address of the MikiRouter
    address public mikiRouter;

    /// @notice The address of the MikiReceiver
    address public mikiReceiver;

    /* ----------------------------- Erorrs -------------------------------- */

    /// @notice Error for invalid router
    error InvalidRouter();

    /* ----------------------------- Constructor -------------------------------- */
    /**
     * @notice Constructor
     * @param _mikiRouter The address of the MikiRouter
     * @param _mikiReceiver The address of the MikiReceiver
     * @param _initialOwner The address of the initial owner
     */
    constructor(address _mikiRouter, address _mikiReceiver, address _initialOwner) Ownable(_initialOwner) {
        mikiRouter = _mikiRouter;
        mikiReceiver = _mikiReceiver;
    }

    /**
     * @notice This function is the receiver of the messages and ETH from the MikiRouter operated by Gelato
     * @param srcChainId The source chain id
     * @param amount The amount of ETH
     * @param payload The payload of the message
     */
    function mikiReceiveETH(uint256 srcChainId, uint256 amount, bytes calldata payload) external payable {
        if (msg.sender != mikiRouter) {
            revert InvalidRouter();
        }

        (address sender, address receiver, bytes memory messageWithId) = abi.decode(payload, (address, address, bytes));

        (bytes32 id, bytes memory message) = abi.decode(messageWithId, (bytes32, bytes));

        IMikiReceiver(mikiReceiver).mikiReceive{ value: amount }(
            srcChainId, sender, receiver, address(0), amount, message, id
        );
    }

    fallback() external payable { }

    receive() external payable { }
}
