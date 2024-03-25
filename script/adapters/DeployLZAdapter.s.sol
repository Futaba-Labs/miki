// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "../Base.s.sol";
import { GaslessETHTokenPool } from "../../src/pools/GaslessETHTokenPool.sol";
import { LayerZeroAdapter } from "../../src/adapters/LayerZeroAdapter.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeployLZAdapter is BaseScript {
    uint256[] chainIds = [11_155_420];
    uint16[] chainIdUint16 = [10_232];
    uint32[] eids = [40_232];
    address public stargateRouter = 0xb2d85b2484c910A6953D28De5D3B8d204f7DDf15;
    address public gateway = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    address[] public receivers = [0x175EC2f76e71f7a0f28B29244bd947a40ff11642]; // Optimism Sepolia Receiver
    address public owner;
    GaslessETHTokenPool public ethTokenPool = GaslessETHTokenPool(payable(0xaaD783B36B84Ad14979Ce68DeECb390523784502));
    LayerZeroAdapter public lzAdapter;

    function run() public broadcast {
        owner = broadcaster;

        // Instantiate the BridgeAdapterMock.
        lzAdapter = new LayerZeroAdapter(owner, stargateRouter, gateway, chainIds, chainIdUint16);

        // Set the bridge adapter.
        for (uint256 i; i < chainIds.length; i++) {
            ethTokenPool.setBridgeAdapter(chainIds[i], address(lzAdapter));
        }

        // set eids
        lzAdapter.setEids(chainIds, eids);

        // Set the receiver.
        lzAdapter.setChainIdToReceivers(chainIds, receivers);
    }
}
