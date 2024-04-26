// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { IMikiAppReceiver } from "../interfaces/IMikiAppReceiver.sol";
import { IMikiReceiver } from "../interfaces/IMikiReceiver.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MikiReceiver is Ownable, IMikiReceiver {
    mapping(address adapter => bool isAdapter) public adapters;
    /* ----------------------------- Events -------------------------------- */

    event SentMsgAndToken(
        bytes32 id,
        uint256 _srcChainId,
        address _srcAddress,
        address _token,
        address _receiver,
        uint256 _amountLD,
        bytes _message
    );

    event SentMsg(bytes32 id, uint256 _srcChainId, address _srcAddress, address _receiver, bytes _message);

    event FailedMsgAndToken(
        bytes32 id,
        uint256 _srcChainId,
        address _srcAddress,
        address _token,
        address _receiver,
        uint256 _amountLD,
        bytes _message,
        string _reason
    );

    event FailedMsg(
        bytes32 id, uint256 _srcChainId, address _srcAddress, address _receiver, bytes _message, string _reason
    );

    event SetAdapter(address _adapter);

    event RemoveAdapter(address _adapter);

    /* ----------------------------- Erorrs -------------------------------- */

    error TransferFailed();
    error InvalidAdapter();

    /* ----------------------------- Constructor -------------------------------- */
    constructor(address _initialOwner) Ownable(_initialOwner) { }

    /* ----------------------------- External Functions ----------------------------- */

    function mikiReceive(
        uint256 srcChainId,
        address srcAddress,
        address receiver,
        address token,
        uint256 amount,
        bytes calldata message,
        bytes32 id
    )
        external
        payable
    {
        if (adapters[receiver]) {
            revert InvalidAdapter();
        }
        if (amount > 0) {
            if (token != address(0)) {
                bool success = IERC20(token).transfer(receiver, amount);
                if (!success) {
                    revert TransferFailed();
                }

                try IMikiAppReceiver(receiver).mikiReceive(srcChainId, srcAddress, token, amount, message) {
                    emit SentMsgAndToken(id, srcChainId, srcAddress, token, receiver, amount, message);
                } catch Error(string memory reason) {
                    emit FailedMsgAndToken(id, srcChainId, srcAddress, token, receiver, amount, message, reason);
                } catch {
                    emit FailedMsgAndToken(
                        id, srcChainId, srcAddress, token, receiver, amount, message, "Unknown error"
                    );
                }
            } else {
                try IMikiAppReceiver(receiver).mikiReceive{ value: amount }(
                    srcChainId, srcAddress, token, amount, message
                ) {
                    emit SentMsgAndToken(id, srcChainId, srcAddress, address(0), receiver, amount, message);
                } catch Error(string memory reason) {
                    emit FailedMsgAndToken(id, srcChainId, srcAddress, address(0), receiver, amount, message, reason);
                } catch {
                    emit FailedMsgAndToken(
                        id, srcChainId, srcAddress, address(0), receiver, amount, message, "Unknown error"
                    );
                }
            }
        } else {
            try IMikiAppReceiver(receiver).mikiReceiveMsg(srcChainId, srcAddress, message) {
                emit SentMsg(id, srcChainId, srcAddress, receiver, message);
            } catch Error(string memory reason) {
                emit FailedMsg(id, srcChainId, srcAddress, receiver, message, reason);
            } catch {
                emit FailedMsg(id, srcChainId, srcAddress, receiver, message, "Unknown error");
            }
        }
    }

    function setAdapters(address[] memory _adapters) public onlyOwner {
        for (uint256 i = 0; i < _adapters.length; i++) {
            adapters[_adapters[i]] = true;
            emit SetAdapter(_adapters[i]);
        }
    }

    function removeAdapters(address[] calldata _adapters) external onlyOwner {
        for (uint256 i = 0; i < _adapters.length; i++) {
            adapters[_adapters[i]] = false;
            emit RemoveAdapter(_adapters[i]);
        }
    }

    fallback() external payable { }

    receive() external payable { }
}
