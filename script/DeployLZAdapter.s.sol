// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "./Base.s.sol";

import { ETHTokenPool } from "../src/pools/ETHTokenPool.sol";
import { LayerZeroAdapter } from "../src/adapters/LayerZeroAdapter.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeployLZAdapter is BaseScript {
    uint256[] chainIds = [11_155_420, 11_155_111];
    uint16[] chainIdUint16 = [10_232, 10_161];
    address public stargateRouter = 0xb2d85b2484c910A6953D28De5D3B8d204f7DDf15;
    address public receiver = 0xDF63D40e765FA44BEb5c3B1B51358AAD20be4F5A; // Optimism Sepolia Receiver
    address public owner;
    ETHTokenPool public ethTokenPool = ETHTokenPool(0x0942fbCe0901f98c8B0CddB7Dc09eb1022311666);
    LayerZeroAdapter public lzAdapter;

    function run() public broadcast {
        owner = broadcaster;

        // Instantiate the BridgeAdapterMock.
        lzAdapter = new LayerZeroAdapter(owner, stargateRouter, receiver, chainIds, chainIdUint16);

        // Set the bridge adapter.
        for (uint256 i; i < chainIds.length; i++) {
            ethTokenPool.setBridgeAdapter(chainIds[i], address(lzAdapter));
        }
    }
}
