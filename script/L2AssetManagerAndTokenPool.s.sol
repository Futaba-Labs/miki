// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "./Base.s.sol";

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import { L2AssetManager } from "../src/L2AssetManager.sol";
import { ETHTokenPool } from "../src/pools/ETHTokenPool.sol";
import { ERC20TokenPool } from "../src/pools/ERC20TokenPool.sol";
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
    ERC20TokenPool public erc20TokenPool;
    ERC20TokenPool public usdcTokenPool;

    function run() public broadcast {
        string memory chainKey = _getChainKey(block.chainid);

        address mikiAdapterAddr = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.miki.sender"));
        address mikiTokenAddr = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.miki.token"));

        address weth = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".pools.ethTokenPool.underlying"));
        address usdc = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".pools.usdcTokenPool.underlying"));

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
        ETHTokenPool ethTokenPoolImpl = new ETHTokenPool(address(l2AssetManager), weth, owner);
        ethTokenPool = ETHTokenPool(
            payable(
                address(
                    new TransparentUpgradeableProxy(
                        address(ethTokenPoolImpl),
                        address(mikiProxyAdmin),
                        abi.encodeWithSelector(ETHTokenPool.initialize.selector, owner, weth)
                    )
                )
            )
        );

        ERC20TokenPool erc20TokenPoolImpl = new ERC20TokenPool(address(l2AssetManager), mikiTokenAddr, owner);
        erc20TokenPool = ERC20TokenPool(
            payable(
                address(
                    new TransparentUpgradeableProxy(
                        address(erc20TokenPoolImpl),
                        address(mikiProxyAdmin),
                        abi.encodeWithSelector(ERC20TokenPool.initialize.selector, owner, mikiTokenAddr)
                    )
                )
            )
        );

        ERC20TokenPool usdcTokenPoolImpl = new ERC20TokenPool(address(l2AssetManager), usdc, owner);
        usdcTokenPool = ERC20TokenPool(
            payable(
                address(
                    new TransparentUpgradeableProxy(
                        address(usdcTokenPoolImpl),
                        address(mikiProxyAdmin),
                        abi.encodeWithSelector(ERC20TokenPool.initialize.selector, owner, usdc)
                    )
                )
            )
        );

        // Set the native token pool.
        l2AssetManager.setNativeTokenPool(address(ethTokenPool));

        // Set the ERC20 token pool.
        tokenPools.push(address(erc20TokenPool));
        l2AssetManager.setTokenPoolWhitelists(tokenPools, tokenPoolWhitelists);

        MikiAdapter mikiAdapter = MikiAdapter(payable(mikiAdapterAddr));

        // Set the bridge adapter.
        erc20TokenPool.setBridgeAdapter(80_001, address(mikiAdapter));

        // send erc20 to mikiTokenPool
        IERC20(mikiTokenAddr).approve(address(l2AssetManager), 100 ether);
        l2AssetManager.deposit(address(mikiTokenAddr), address(erc20TokenPool), 100 ether);

        // send eth to ethTokenPool
        l2AssetManager.depositETH{ value: 0.1 ether }(0.1 ether);

        // write json
        vm.writeJson(vm.toString(address(ethTokenPool)), deploymentPath, string.concat(chainKey, ".l2AssetManager"));
        vm.writeJson(
            vm.toString(address(ethTokenPool)), deploymentPath, string.concat(chainKey, ".pools.ethTokenPool.pool")
        );
        vm.writeJson(
            vm.toString(address(erc20TokenPool)), deploymentPath, string.concat(chainKey, ".pools.mikiTokenPool.pool")
        );
        vm.writeJson(
            vm.toString(address(usdcTokenPool)), deploymentPath, string.concat(chainKey, ".pools.usdcTokenPool.pool")
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

        ERC20TokenPool tokenPool = ERC20TokenPool(payable(mikiTokenPoolAddr));

        tokenPool.crossChainContractCallWithAsset{ value: fee * 120 / 100 }(
            dstChainId, aaveV3ReceiverAddr, message, fee * 120 / 100, amount, params
        );
    }
}
