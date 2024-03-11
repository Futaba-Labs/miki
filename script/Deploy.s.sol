// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "./Base.s.sol";

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import { L2AssetManager } from "../src/L2AssetManager.sol";
import { ETHTokenPool } from "../src/pools/ETHTokenPool.sol";
import { L2BridgeAdapter } from "../src/adapters/L2BridgeAdapter.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract Deploy is BaseScript {
    address public weth = 0x980B62Da83eFf3D4576C647993b0c1D7faf17c73;
    address public spokePool = 0x7E63A5f1a8F0B4d0934B2f2327DAED3F6bb2ee75;
    uint256 public dstCahinId = 11_155_420;
    address public owner;
    ProxyAdmin public mikiProxyAdmin;
    L2AssetManager public l2AssetManager;
    ETHTokenPool public ethTokenPool;
    L2BridgeAdapter public bridgeAdapter;

    function run() public broadcast {
        owner = broadcaster;
        mikiProxyAdmin = new ProxyAdmin(owner);
        L2AssetManager l2AssetManagerImplementation = new L2AssetManager();
        l2AssetManager = L2AssetManager(
            address(
                new TransparentUpgradeableProxy(
                    address(l2AssetManagerImplementation),
                    address(mikiProxyAdmin),
                    abi.encodeWithSelector(L2AssetManager.initialize.selector, owner)
                )
            )
        );
        ethTokenPool = new ETHTokenPool(owner, address(l2AssetManager), owner, weth);

        // Set the native token pool.
        l2AssetManager.setNativeTokenPool(address(ethTokenPool));

        // Instantiate the BridgeAdapterMock.
        bridgeAdapter = new L2BridgeAdapter(spokePool);

        // Set the bridge adapter.
        ethTokenPool.setBridgeAdapter(dstCahinId, address(bridgeAdapter));
    }
}
