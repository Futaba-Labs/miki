// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "./Base.s.sol";

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import { L2AssetManager } from "../src/L2AssetManager.sol";
import { ETHTokenPool } from "../src/pools/ETHTokenPool.sol";
import { MikiTokenPool } from "../src/pools/MikiTokenPool.sol";
import { MikiAdapter } from "../src/adapters/MikiAdapter.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting

contract Deploy is BaseScript {
    address public weth = 0x980B62Da83eFf3D4576C647993b0c1D7faf17c73;
    address public mikiToken = 0x587AF5e09a4e6011d5B7C38d45344792D6800898;
    uint256 public dstChainId = 11_155_420;
    address public owner;
    address[] public tokenPools;
    bool[] public tokenPoolWhitelists = [true];
    ProxyAdmin public mikiProxyAdmin;
    L2AssetManager public l2AssetManager;
    ETHTokenPool public ethTokenPool;
    MikiTokenPool public mikiTokenPool;
    MikiAdapter public mikiAdapter = MikiAdapter(payable(0x700596f9F85b7E9c7bF6a2F58134362A22873A18));

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
        ethTokenPool = new ETHTokenPool(owner, address(l2AssetManager), weth, owner);
        mikiTokenPool = new MikiTokenPool(owner, address(l2AssetManager), mikiToken, owner);

        // Set the native token pool.
        l2AssetManager.setNativeTokenPool(address(ethTokenPool));

        // Set the ERC20 token pool.
        tokenPools.push(address(mikiTokenPool));
        l2AssetManager.setTokenPoolWhitelists(tokenPools, tokenPoolWhitelists);

        // Set the bridge adapter.
        mikiTokenPool.setBridgeAdapter(dstChainId, address(mikiAdapter));

        // send erc20 to mikiTokenPool
        IERC20(mikiToken).approve(address(l2AssetManager), 10 ether);
        l2AssetManager.deposit(address(mikiToken), address(mikiTokenPool), 10 ether);

        // send eth to ethTokenPool
        l2AssetManager.depositETH{ value: 0.1 ether }(0.1 ether);
    }
}
