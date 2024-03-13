// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "../Base.s.sol";

import { ETHTokenPool } from "../../src/pools/ETHTokenPool.sol";
import { LayerZeroAdapter } from "../../src/adapters/LayerZeroAdapter.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeployLZAdapter is BaseScript {
    uint256[] chainIds = [11_155_420];
    uint16[] chainIdUint16 = [10_232];
    address public stargateRouter = 0xb2d85b2484c910A6953D28De5D3B8d204f7DDf15;
    address public gateway = 0x6098e96a28E02f27B1e6BD381f870F1C8Bd169d3;
    address[] public receivers = [0xEe88b30245471077A725B0F38CfBd91182d9b976]; // Optimism Sepolia Receiver
    address public owner;
    ETHTokenPool public ethTokenPool = ETHTokenPool(payable(0x02f70133DA3f51D878224C967f9677EaEf285D47));
    LayerZeroAdapter public lzAdapter;

    function run() public broadcast {
        owner = broadcaster;

        // Instantiate the BridgeAdapterMock.
        lzAdapter = new LayerZeroAdapter(owner, stargateRouter, gateway, chainIds, chainIdUint16);

        // Set the bridge adapter.
        for (uint256 i; i < chainIds.length; i++) {
            ethTokenPool.setBridgeAdapter(chainIds[i], address(lzAdapter));
        }

        // Set the receiver.
        lzAdapter.setChainIdToReceivers(chainIds, receivers);
    }
}
