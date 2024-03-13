// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { AxelarExecutable } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

contract AxelarReceiver is AxelarExecutable {
    using Address for address;

    event ExecutedFunctionCall(address sender, address receiver, bytes encodedSelector, bytes data);
    /* ----------------------------- Constructor -------------------------------- */

    constructor(address _axelarGateway) AxelarExecutable(_axelarGateway) { }

    function _execute(
        string calldata _sourceChain,
        string calldata _sourceAddress,
        bytes calldata _payload
    )
        internal
        virtual
        override
    {
        // Decode the payload
        (address sender, address receiver, bytes memory encodedSelector) =
            abi.decode(_payload, (address, address, bytes));

        // Call the receiver
        bytes memory data = receiver.functionCall(encodedSelector);

        emit ExecutedFunctionCall(sender, receiver, encodedSelector, data);
    }
}
