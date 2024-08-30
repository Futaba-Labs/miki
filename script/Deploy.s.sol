// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "./Base.s.sol";
import { console2 } from "forge-std/src/console2.sol";
import {
    TransparentUpgradeableProxy,
    ITransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { ERC1967Utils } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { L2AssetManager } from "../src/L2AssetManager.sol";
import { TokenPoolBase } from "../src/pools/TokenPoolBase.sol";
import { ETHTokenPool } from "../src/pools/ETHTokenPool.sol";
import { GaslessETHTokenPool } from "../src/pools/GaslessETHTokenPool.sol";
import { ERC20TokenPool } from "../src/pools/ERC20TokenPool.sol";
import { EthAdapter } from "../src/adapters/EthAdapter.sol";
import { LayerZeroAdapter } from "../src/adapters/LayerZeroAdapter.sol";
import { AxelarAdapter } from "../src/adapters/AxelarAdapter.sol";
import { AxelarReceiver } from "../src/adapters/AxelarReceiver.sol";
import { MikiRouterReceiver } from "../src/adapters/MikiRouterReceiver.sol";
import { MikiReceiver } from "../src/adapters/MikiReceiver.sol";
import { LayerZeroReceiver } from "../src/adapters/LayerZeroReceiver.sol";
import { NFTReceiver } from "../src/examples/NFTReceiver.sol";
import { AAVEV3Receiver } from "../src/examples/AAVEV3Receiver.sol";
import { SampleAMM } from "../src/examples/SampleAMM.sol";

contract Deploy is BaseScript {
    // Miki Contracts
    L2AssetManager public l2AssetManager;
    L2AssetManager public l2AssetManagerImpl;
    ETHTokenPool public ethTokenPool;
    ETHTokenPool public ethTokenPoolImpl;
    ERC20TokenPool public usdcTokenPool;
    ERC20TokenPool public usdcTokenPoolImpl;

    // Miki Adapters
    EthAdapter public ethAdapter;
    LayerZeroAdapter public lzAdapter;
    LayerZeroReceiver public lzReceiver;
    AxelarReceiver public axelarReceiver;
    AxelarAdapter public axelarAdapter;
    MikiRouterReceiver public mikiRouterReceiver;
    MikiReceiver public mikiReceiver;

    // Miki Examples
    NFTReceiver public nftReceiver;
    AAVEV3Receiver public aaveV3Receiver;
    SampleAMM public sampleAMM;

    // Other params
    uint256 private chainId;
    string private chainKey;
    address private owner;
    uint256 private hubChainId = networks[Chains.ArbitrumSepolia].chainId;
    address private mikiRouter;
    address private orbiterRouter;
    address private orbiterMaker;
    address private lzGateway;
    uint256[] private chainIds;
    uint32[] private eids;
    uint16[] private codes;
    string public uri = "ipfs://QmeuC3tFtndSF1pBTzZxUmArWiBFv3ozNhEnAPFKJp9T1E/0";

    function run() public broadcast {
        _setup();

        mikiRouter =
            vm.parseJsonAddress(deploymentsJson, string.concat(_getChainKey(hubChainId), ".adapters.eth.mikiRouter"));

        if (chainId == hubChainId) {
            _deployOnHubChain();
        } else {
            _deployOnSpokeChain();
        }
    }

    function _deployOnHubChain() internal {
        // deploy adapters
        orbiterRouter = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.eth.orbiterRouter"));
        orbiterMaker = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.eth.orbiterMaker"));
        lzGateway = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.layerZero.gateway"));

        lzAdapter = new LayerZeroAdapter(broadcaster, lzGateway, chainIds, eids);
        ethAdapter =
            new EthAdapter(payable(orbiterRouter), orbiterMaker, payable(mikiRouter), address(lzAdapter), broadcaster);

        // set identification codes for orbiter
        ethAdapter.setIdentificationCodes(chainIds, codes);

        // deploy asset manager
        l2AssetManagerImpl = new L2AssetManager();
        l2AssetManager = L2AssetManager(
            address(
                new TransparentUpgradeableProxy(
                    address(l2AssetManagerImpl),
                    owner,
                    abi.encodeWithSelector(L2AssetManager.initialize.selector, owner)
                )
            )
        );

        // deploy token pool
        address weth = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".pools.ethTokenPool.underlying"));
        address usdc = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".pools.usdcTokenPool.underlying"));

        ethTokenPoolImpl = new GaslessETHTokenPool(address(l2AssetManager), owner);
        ethTokenPool = GaslessETHTokenPool(
            payable(
                address(
                    new TransparentUpgradeableProxy(
                        address(ethTokenPoolImpl),
                        owner,
                        abi.encodeWithSelector(TokenPoolBase.initialize.selector, owner, weth)
                    )
                )
            )
        );

        usdcTokenPoolImpl = new ERC20TokenPool(address(l2AssetManager), owner);
        usdcTokenPool = ERC20TokenPool(
            payable(
                address(
                    new TransparentUpgradeableProxy(
                        address(usdcTokenPoolImpl),
                        owner,
                        abi.encodeWithSelector(TokenPoolBase.initialize.selector, owner, usdc)
                    )
                )
            )
        );

        // Set the native token pool
        l2AssetManager.setNativeTokenPool(address(ethTokenPool));

        // Set usdc token pool
        address[] memory tokenPools = new address[](1);
        tokenPools[0] = address(usdcTokenPool);
        bool[] memory tokenPoolWhitelists = new bool[](1);
        tokenPoolWhitelists[0] = true;
        l2AssetManager.setTokenPoolWhitelists(tokenPools, tokenPoolWhitelists);

        // Set chain ids
        lzAdapter.setEids(chainIds, eids);

        // Set adapter
        for (uint256 i = 0; i < chainIds.length; i++) {
            ethTokenPool.setBridgeAdapter(chainIds[i], address(ethAdapter));
        }

        // write json
        vm.writeJson(vm.toString(address(ethAdapter)), deploymentPath, string.concat(chainKey, ".adapters.eth.sender"));
        vm.writeJson(
            vm.toString(address(lzAdapter)), deploymentPath, string.concat(chainKey, ".adapters.layerZero.sender")
        );
        vm.writeJson(
            vm.toString(address(l2AssetManager)), deploymentPath, string.concat(chainKey, ".l2AssetManagerProxy")
        );
        vm.writeJson(
            vm.toString(address(l2AssetManagerImpl)), deploymentPath, string.concat(chainKey, ".l2AssetManagerImpl")
        );
        vm.writeJson(
            vm.toString(address(ethTokenPool)), deploymentPath, string.concat(chainKey, ".pools.ethTokenPool.proxy")
        );
        vm.writeJson(
            vm.toString(address(ethTokenPoolImpl)), deploymentPath, string.concat(chainKey, ".pools.ethTokenPool.impl")
        );

        vm.writeJson(
            vm.toString(address(usdcTokenPool)), deploymentPath, string.concat(chainKey, ".pools.usdcTokenPool.proxy")
        );
        vm.writeJson(
            vm.toString(address(usdcTokenPoolImpl)),
            deploymentPath,
            string.concat(chainKey, ".pools.usdcTokenPool.impl")
        );
    }

    function _deployOnSpokeChain() internal {
        // deploy receiver
        mikiReceiver = new MikiReceiver(owner);

        if (chainId != networks[Chains.ZkSyncSepolia].chainId) {
            // deploy lz receiver
            address receiver;
            if (chainId != networks[Chains.MantleSepolia].chainId) {
                address gateway =
                    vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.layerZero.gateway"));
                lzReceiver = new LayerZeroReceiver(gateway, address(mikiReceiver), gateway, owner);

                vm.writeJson(
                    vm.toString(address(lzReceiver)),
                    deploymentPath,
                    string.concat(chainKey, ".adapters.layerZero.receiver")
                );
                receiver = address(lzReceiver);

                // Set chainIds
                lzReceiver.setChainIds(eids, chainIds);
            } else {
                _deployAxelarReceiver();
                receiver = address(axelarReceiver);
            }

            // Set adapters
            address[] memory adapters = new address[](1);
            adapters[0] = address(receiver);
            mikiReceiver.setAdapters(adapters);
        }

        if (
            chainId == networks[Chains.BaseSepolia].chainId || chainId == networks[Chains.OptimismSepolia].chainId
                || chainId == networks[Chains.ScrollSepolia].chainId || chainId == networks[Chains.BlastSepolia].chainId
        ) {
            // deploy miki router receiver
            mikiRouterReceiver = new MikiRouterReceiver(mikiRouter, address(mikiReceiver), owner);

            // write json
            vm.writeJson(
                vm.toString(address(mikiRouterReceiver)),
                deploymentPath,
                string.concat(chainKey, ".adapters.eth.receiver")
            );

            if (
                chainId == networks[Chains.BaseSepolia].chainId || chainId == networks[Chains.OptimismSepolia].chainId
                    || chainId == networks[Chains.ScrollSepolia].chainId
            ) {
                // deploy examples
                address permit2 =
                    vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".examples.aave.permit2"));
                address weth =
                    vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".examples.aave.weth.underlying"));
                address token0 = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".examples.amm.token0"));
                address token1 = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".examples.amm.token1"));

                sampleAMM = new SampleAMM(token0, token1);
                aaveV3Receiver = new AAVEV3Receiver(owner, permit2, address(sampleAMM), address(mikiReceiver), weth);

                // Set weth token pools
                string memory tokenKey = string.concat(chainKey, ".examples.aave.weth");

                address underlyingToken = vm.parseJsonAddress(deploymentsJson, string.concat(tokenKey, ".underlying"));
                address aToken = vm.parseJsonAddress(deploymentsJson, string.concat(tokenKey, ".aToken"));
                address pool = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".examples.aave.pool"));

                AAVEV3Receiver(payable(address(aaveV3Receiver))).setTokenPool(underlyingToken, aToken, pool);

                vm.writeJson(
                    vm.toString(address(aaveV3Receiver)),
                    deploymentPath,
                    string.concat(chainKey, ".examples.aave.receiver")
                );
            }

            // set adapters
            address[] memory adapters = new address[](1);
            adapters[0] = address(mikiRouterReceiver);
            mikiReceiver.setAdapters(adapters);
        }

        if (chainId != networks[Chains.ZkSyncSepolia].chainId) {
            nftReceiver = new NFTReceiver(uri, address(mikiReceiver));
            vm.writeJson(vm.toString(address(nftReceiver)), deploymentPath, string.concat(chainKey, ".examples.nft"));
        }

        // write json
        vm.writeJson(
            vm.toString(address(mikiReceiver)), deploymentPath, string.concat(chainKey, ".adapters.mikiReceiver")
        );
    }

    // upgrade contracts (L2AssetManager, ETHTokenPool, ERC20TokenPool)
    function upgrade() public broadcast {
        chainId = block.chainid;
        console2.log("ChainId: %s", chainId);
        chainKey = _getChainKey(chainId);

        owner = 0x609b8fc63842ECB8635FCFAe7e6040416A6D2dFb;
        console2.log("Owner: %s", owner);

        address ethTokenPoolAddr =
            vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".pools.ethTokenPool.proxy"));
        address usdcTokenPoolAddr =
            vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".pools.usdcTokenPool.proxy"));
        address l2AssetManagerAddr =
            vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".l2AssetManagerProxy"));

        // deploy impls
        // l2AssetManagerImpl = new L2AssetManager();
        ethTokenPoolImpl = new GaslessETHTokenPool(l2AssetManagerAddr, owner);
        // usdcTokenPoolImpl = new ERC20TokenPool(l2AssetManagerAddr, owner);

        // upgrade contracts
        // _upgrade(l2AssetManagerAddr, address(l2AssetManagerImpl), "");
        _upgrade(ethTokenPoolAddr, address(ethTokenPoolImpl), "");
        // _upgrade(usdcTokenPoolAddr, address(usdcTokenPoolImpl), "");

        // write json
        // vm.writeJson(
        //     vm.toString(address(l2AssetManagerImpl)), deploymentPath, string.concat(chainKey, ".l2AssetManagerImpl")
        // );
        vm.writeJson(
            vm.toString(address(ethTokenPoolImpl)), deploymentPath, string.concat(chainKey, ".pools.ethTokenPool.impl")
        );
        // vm.writeJson(
        //     vm.toString(address(usdcTokenPoolImpl)),
        //     deploymentPath,
        //     string.concat(chainKey, ".pools.usdcTokenPool.impl")
        // );
    }

    function deployEthAdapter() public broadcast {
        // Set configuration
        _setup();

        // Get routers
        mikiRouter =
            vm.parseJsonAddress(deploymentsJson, string.concat(_getChainKey(hubChainId), ".adapters.eth.mikiRouter"));
        orbiterRouter = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.eth.orbiterRouter"));
        orbiterMaker = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.eth.orbiterMaker"));
        lzGateway = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.layerZero.gateway"));

        address lzAdapterAddr =
            vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.layerZero.sender"));

        // Deploy adapter
        ethAdapter = new EthAdapter(orbiterRouter, orbiterMaker, payable(mikiRouter), lzAdapterAddr, broadcaster);

        // Get ETH Token Pool
        address ethTokenPoolAddr =
            vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".pools.ethTokenPool.proxy"));

        // Set adapter
        for (uint256 i = 0; i < chainIds.length; i++) {
            GaslessETHTokenPool(payable(ethTokenPoolAddr)).setBridgeAdapter(chainIds[i], address(ethAdapter));
        }
    }

    function deployMikiRouterReceiver() public broadcast {
        _setup();

        mikiRouter =
            vm.parseJsonAddress(deploymentsJson, string.concat(_getChainKey(hubChainId), ".adapters.eth.mikiRouter"));
        address mikiReceiverAddr =
            vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.mikiReceiver"));
        address lzReceiver =
            vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.layerZero.receiver"));

        mikiRouterReceiver = new MikiRouterReceiver(mikiRouter, mikiReceiverAddr, owner);

        // set adapters
        address[] memory adapters = new address[](2);
        adapters[0] = address(mikiRouterReceiver);
        adapters[1] = address(lzReceiver);
        MikiReceiver(payable(mikiReceiverAddr)).setAdapters(adapters);

        vm.writeJson(
            vm.toString(address(mikiRouterReceiver)), deploymentPath, string.concat(chainKey, ".adapters.eth.receiver")
        );
    }

    function deployAxelarAdapter() public broadcast {
        _deployAxelarAdapter();
    }

    function _deployAxelarAdapter() internal {
        // Set configuration
        chainId = block.chainid;
        console2.log("ChainId: %s", chainId);
        chainKey = _getChainKey(chainId);

        owner = broadcaster;
        console2.log("Owner: %s", owner);

        // Get routers
        address axelarGateway =
            vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.axelar.gateway"));
        address axelarGasService =
            vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.axelar.gasService"));

        // deploy axelar adapter
        axelarAdapter = new AxelarAdapter(owner, axelarGateway, axelarGasService);

        // write json
        vm.writeJson(
            vm.toString(address(axelarAdapter)), deploymentPath, string.concat(chainKey, ".adapters.axelar.sender")
        );

        // set chain name
        uint256[] memory chainIdsForAxelar = new uint256[](1);
        string[] memory chainNames = new string[](1);
        chainIdsForAxelar[0] = networks[Chains.MantleSepolia].chainId;
        chainNames[0] = "mantle-sepolia";
        axelarAdapter.setChainIdToDomains(chainIdsForAxelar, chainNames);

        // set bridge adapter
        address ethTokenPoolAddr =
            vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".pools.ethTokenPool.proxy"));

        ethTokenPool = GaslessETHTokenPool(payable(ethTokenPoolAddr));
        ethTokenPool.setBridgeAdapter(networks[Chains.MantleSepolia].chainId, address(axelarAdapter));
    }

    function deployAxelarReceiver() public broadcast {
        _deployAxelarReceiver();
    }

    function _deployAxelarReceiver() internal {
        // Set configuration
        _setup();

        // Get routers
        address mikiReceiverAddr =
            vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.mikiReceiver"));
        address axelarGateway =
            vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.axelar.gateway"));

        // deploy axelar receiver
        axelarReceiver = new AxelarReceiver(axelarGateway, mikiReceiverAddr, owner);

        // write json
        vm.writeJson(
            vm.toString(address(axelarReceiver)), deploymentPath, string.concat(chainKey, ".adapters.axelar.receiver")
        );

        // set chain id
        axelarReceiver.setChainId("arbitrum-sepolia", networks[Chains.ArbitrumSepolia].chainId);
    }

    function setBridgeAdapter(string memory chainName, address adapter) public broadcast {
        _setup();

        uint256 dstChainId = _getChainId(chainName);

        address ethTokenPoolAddr =
            vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".pools.ethTokenPool.proxy"));

        if (adapter == address(0)) {
            adapter = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.eth.sender"));
        }

        GaslessETHTokenPool(payable(ethTokenPoolAddr)).setBridgeAdapter(dstChainId, adapter);
    }

    function setEids() public broadcast {
        _setup();
        address lzAdapterAddr =
            vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.layerZero.sender"));

        LayerZeroAdapter(lzAdapterAddr).setEids(chainIds, eids);
    }

    function _setup() internal {
        // Set configuration
        chainId = block.chainid;
        console2.log("ChainId: %s", chainId);
        chainKey = _getChainKey(chainId);

        owner = broadcaster;
        console2.log("Owner: %s", owner);

        for (uint256 i = 0; i < deployedChains.length; i++) {
            Chains chain = deployedChains[i];
            string memory targetChainKey = _getChainKey(uint256(networks[chain].chainId));
            // uint16 code =
            //     uint16(vm.parseJsonUint(deploymentsJson, string.concat(targetChainKey, ".adapters.orbiter.code")));
            uint256 id = networks[chain].chainId;
            uint32 eid = networks[chain].eid;
            chainIds.push(id);
            eids.push(eid);
            // codes.push(code);
        }
    }

    function _upgrade(address proxy, address impl, bytes memory data) internal {
        bytes32 adminSlot = vm.load(proxy, ERC1967Utils.ADMIN_SLOT);
        if (adminSlot == bytes32(0)) {
            // No admin contract: upgrade directly using interface
            ITransparentUpgradeableProxy(proxy).upgradeToAndCall(impl, data);
        } else {
            ProxyAdmin admin = ProxyAdmin(address(uint160(uint256(adminSlot))));
            admin.upgradeAndCall(ITransparentUpgradeableProxy(proxy), impl, data);
        }
    }
}
