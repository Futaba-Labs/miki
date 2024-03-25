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
import { OptionsBuilder } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting

contract L2AssetManagerAndTokenPoolScript is BaseScript {
    using OptionsBuilder for bytes;

    address public owner;
    address[] public tokenPools;
    bool[] public tokenPoolWhitelists = [true];
    ProxyAdmin public mikiProxyAdmin;
    L2AssetManager public l2AssetManager;
    ETHTokenPool public ethTokenPool;
    MikiTokenPool public mikiTokenPool;

    function run() public broadcast {
        string memory chainKey = _getChainKey(block.chainid);

        address mikiAdapterAddr = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.miki.sender"));
        address mikiTokenAddr = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.miki.token"));

        address weth = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".pools.ethTokenPool.underlying"));

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
        mikiTokenPool = new MikiTokenPool(owner, address(l2AssetManager), mikiTokenAddr, owner);

        // Set the native token pool.
        l2AssetManager.setNativeTokenPool(address(ethTokenPool));

        // Set the ERC20 token pool.
        tokenPools.push(address(mikiTokenPool));
        l2AssetManager.setTokenPoolWhitelists(tokenPools, tokenPoolWhitelists);

        MikiAdapter mikiAdapter = MikiAdapter(payable(mikiAdapterAddr));

        // Set the bridge adapter.
        mikiTokenPool.setBridgeAdapter(80_001, address(mikiAdapter));

        // send erc20 to mikiTokenPool
        IERC20(mikiTokenAddr).approve(address(l2AssetManager), 100 ether);
        l2AssetManager.deposit(address(mikiTokenAddr), address(mikiTokenPool), 100 ether);

        // send eth to ethTokenPool
        l2AssetManager.depositETH{ value: 0.1 ether }(0.1 ether);

        // write json
        vm.writeJson(vm.toString(address(ethTokenPool)), deploymentPath, string.concat(chainKey, ".l2AssetManager"));
        vm.writeJson(
            vm.toString(address(ethTokenPool)), deploymentPath, string.concat(chainKey, ".pools.ethTokenPool.pool")
        );
        vm.writeJson(
            vm.toString(address(mikiTokenPool)), deploymentPath, string.concat(chainKey, ".pools.mikiTokenPool.pool")
        );
    }

    function crossChainDepositFromTokenPool(
        uint256 dstChainId,
        string memory tokenName,
        uint256 amount
    )
        public
        broadcast
    {
        string memory chainKey = _getChainKey(block.chainid);
        string memory targetChainKey = _getChainKey(dstChainId);
        string memory tokenKey = string.concat(targetChainKey, ".examples.aave.", tokenName);

        address underlyingToken = vm.parseJsonAddress(deploymentsJson, string.concat(tokenKey, ".underlying"));
        address aaveV3ReceiverAddr =
            vm.parseJsonAddress(deploymentsJson, string.concat(targetChainKey, ".examples.aave.receiver"));
        address mikiAdapterAddr = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.miki.sender"));
        address mikiTokenAddr = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.miki.token"));
        address mikiTokenPoolAddr =
            vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".pools.mikiTokenPool.pool"));

        MikiAdapter mikiAdapter = MikiAdapter(mikiAdapterAddr);

        bytes memory option =
            OptionsBuilder.newOptions().addExecutorLzReceiveOption(200_000, 0).addExecutorLzComposeOption(0, 200_000, 0);

        bytes memory params = abi.encode(amount, option);
        bytes memory message = abi.encode(underlyingToken);

        uint256 fee =
            mikiAdapter.estimateFee(broadcaster, dstChainId, aaveV3ReceiverAddr, mikiTokenAddr, message, amount, params);

        IERC20(mikiTokenAddr).approve(mikiAdapterAddr, amount);

        MikiTokenPool tokenPool = MikiTokenPool(payable(mikiTokenPoolAddr));

        tokenPool.crossChainContractCallWithAsset{ value: fee * 120 / 100 }(
            dstChainId, aaveV3ReceiverAddr, message, fee * 120 / 100, amount, params
        );
    }
}
