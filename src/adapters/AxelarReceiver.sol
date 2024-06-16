// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { AxelarExecutable } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IMikiReceiver } from "../interfaces/IMikiReceiver.sol";

contract AxelarReceiver is AxelarExecutable, Ownable {
    using Address for address;

    /// @notice The miki receiver address
    address public immutable MIKI_RECEIVER;

    mapping(string chainName => uint256 chainId) public chainIdOf;

    event ExecutedFunctionCall(address sender, address receiver, bytes encodedSelector, bytes data);
    event SetChainId(string chainName, uint256 chainId);

    error NoChainId(string chainName);
    /* ----------------------------- Constructor -------------------------------- */

    constructor(
        address _axelarGateway,
        address _mikiReceiver,
        address _initialOwner
    )
        AxelarExecutable(_axelarGateway)
        Ownable(_initialOwner)
    {
        MIKI_RECEIVER = _mikiReceiver;
    }

    function _execute(string calldata sourceChain, string calldata, bytes calldata payload) internal virtual override {
        uint256 chainId = chainIdOf[sourceChain];

        if (chainId == 0) revert NoChainId(sourceChain);

        (address sender, address receiver, bytes memory messageWithId) = abi.decode(payload, (address, address, bytes));
        (bytes32 id, bytes memory message) = abi.decode(messageWithId, (bytes32, bytes));

        IMikiReceiver(MIKI_RECEIVER).mikiReceive(chainId, sender, receiver, address(0), 0, message, id);
    }

    function setChainIds(string[] calldata chainNames, uint256[] calldata chainIds) external {
        for (uint256 i; i < chainNames.length; i++) {
            setChainId(chainNames[i], chainIds[i]);
        }
    }

    function setChainId(string calldata chainName, uint256 chainId) public onlyOwner {
        chainIdOf[chainName] = chainId;
        emit SetChainId(chainName, chainId);
    }
}
