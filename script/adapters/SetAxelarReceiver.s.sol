// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "../Base.s.sol";
import { console2 } from "forge-std/src/console2.sol";
import { AxelarAdapter } from "../../src/adapters/AxelarAdapter.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract SetAxelarReceiverScript is BaseScript {
    function run() public broadcast {
        uint256 chainId = block.chainid;
        console2.log("ChainId: %s", chainId);
        string memory chainKey = _getChainKey(chainId);
        string memory dstChainKey = _getChainKey(networks[Chains.MantleSepolia].chainId);
        // get axelar receiver
        address axelarReceiverAddr =
            vm.parseJsonAddress(deploymentsJson, string.concat(dstChainKey, ".adapters.axelar.receiver"));
        address axelarAdapterAddr =
            vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.axelar.sender"));

        // set receiver
        uint256[] memory chainIds = new uint256[](1);
        chainIds[0] = networks[Chains.MantleSepolia].chainId;
        address[] memory receivers = new address[](1);
        receivers[0] = axelarReceiverAddr;
        AxelarAdapter(axelarAdapterAddr).setChainIdToReceivers(chainIds, receivers);
    }
}
