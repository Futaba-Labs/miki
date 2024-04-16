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
import { ETHTokenPool } from "../src/pools/ETHTokenPool.sol";
import { ERC20TokenPool } from "../src/pools/ERC20TokenPool.sol";
import { EthAdapter } from "../src/adapters/EthAdapter.sol";
import { LayerZeroAdapter } from "../src/adapters/LayerZeroAdapter.sol";
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
    MikiRouterReceiver public mikiRouterReceiver;
    MikiReceiver public mikiReceiver;

    // Miki Examples
    NFTReceiver public nftReceiver;
    AAVEV3Receiver public aaveV3Receiver;
    SampleAMM public sampleAMM;

    // Other params
    string private chainKey;
    address private owner;
    uint256 private hubChainId = networks[Chains.ArbitrumSepolia].chainId;
    address private mikiRouter;
    address private orbiterRouter;
    address private lzGateway;
    uint256[] private chainIds;
    uint32[] private eids;
    uint16[] private codes;
    string public uri = "ipfs://QmeuC3tFtndSF1pBTzZxUmArWiBFv3ozNhEnAPFKJp9T1E/0";

    function run() public broadcast {
        uint256 chainId = block.chainid;
        console2.log("ChainId: %s", chainId);
        chainKey = _getChainKey(chainId);

        owner = broadcaster;
        console2.log("Owner: %s", owner);

        // Set configuration
        Chains[] memory chains = new Chains[](1);
        chains[0] = Chains.OptimismSepolia;

        for (uint256 i = 0; i < chains.length; i++) {
            Chains chain = chains[i];
            string memory targetChainKey = _getChainKey(uint256(networks[chain].chainId));
            uint16 code =
                uint16(vm.parseJsonUint(deploymentsJson, string.concat(targetChainKey, ".adapters.orbiter.code")));
            uint256 id = networks[chain].chainId;
            uint32 eid = networks[chain].eid;
            chainIds.push(id);
            eids.push(eid);
            codes.push(code);
        }

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
        lzGateway = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.layerZero.gateway"));

        lzAdapter = new LayerZeroAdapter(broadcaster, lzGateway, chainIds, eids);
        ethAdapter = new EthAdapter(payable(mikiRouter), payable(orbiterRouter), address(lzAdapter), broadcaster);

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

        ethTokenPoolImpl = new ETHTokenPool(address(l2AssetManager), weth, owner);
        ethTokenPool = ETHTokenPool(
            payable(
                address(
                    new TransparentUpgradeableProxy(
                        address(ethTokenPoolImpl),
                        owner,
                        abi.encodeWithSelector(ETHTokenPool.initialize.selector, owner, weth)
                    )
                )
            )
        );

        usdcTokenPoolImpl = new ERC20TokenPool(address(l2AssetManager), usdc, owner);
        usdcTokenPool = ERC20TokenPool(
            payable(
                address(
                    new TransparentUpgradeableProxy(
                        address(usdcTokenPoolImpl),
                        owner,
                        abi.encodeWithSelector(ERC20TokenPool.initialize.selector, owner, usdc)
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

        // deploy miki router receiver
        mikiRouterReceiver = new MikiRouterReceiver(mikiRouter, address(mikiReceiver), owner);

        // deploy lz receiver
        address gateway = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.layerZero.gateway"));
        lzReceiver = new LayerZeroReceiver(gateway, address(mikiReceiver), gateway, owner);

        // deploy examples
        address permit2 = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".examples.aave.permit2"));
        address weth = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".examples.aave.weth.underlying"));
        address token0 = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".examples.amm.token0"));
        address token1 = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".examples.amm.token1"));

        sampleAMM = new SampleAMM(token0, token1);
        aaveV3Receiver = new AAVEV3Receiver(owner, permit2, address(sampleAMM), address(mikiReceiver), weth);
        nftReceiver = new NFTReceiver(uri, address(mikiReceiver));

        // Set adapters
        address[] memory adapters = new address[](2);
        adapters[0] = address(lzAdapter);
        adapters[1] = address(mikiRouterReceiver);
        mikiReceiver.setAdapters(adapters);

        // Set chainIds
        lzReceiver.setChainIds(eids, chainIds);

        // Set weth token pools
        string memory tokenKey = string.concat(chainKey, ".examples.aave.weth");

        address underlyingToken = vm.parseJsonAddress(deploymentsJson, string.concat(tokenKey, ".underlying"));
        address aToken = vm.parseJsonAddress(deploymentsJson, string.concat(tokenKey, ".aToken"));
        address pool = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".examples.aave.pool"));

        AAVEV3Receiver(payable(address(aaveV3Receiver))).setTokenPool(underlyingToken, aToken, pool);

        // write json
        vm.writeJson(
            vm.toString(address(mikiReceiver)), deploymentPath, string.concat(chainKey, ".adapters.mikiReceiver")
        );
        vm.writeJson(
            vm.toString(address(mikiRouterReceiver)), deploymentPath, string.concat(chainKey, ".adapters.eth.receiver")
        );
        vm.writeJson(
            vm.toString(address(lzReceiver)), deploymentPath, string.concat(chainKey, ".adapters.layerZero.receiver")
        );
        vm.writeJson(
            vm.toString(address(aaveV3Receiver)), deploymentPath, string.concat(chainKey, ".examples.aave.receiver")
        );
        vm.writeJson(vm.toString(address(nftReceiver)), deploymentPath, string.concat(chainKey, ".examples.nft"));
    }

    function upgrade() public broadcast {
        uint256 chainId = block.chainid;
        console2.log("ChainId: %s", chainId);
        chainKey = _getChainKey(chainId);

        owner = broadcaster;
        console2.log("Owner: %s", owner);

        address ethTokenPoolAddr =
            vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".pools.ethTokenPool.pool"));
        address usdcTokenPoolAddr =
            vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".pools.usdcTokenPool.pool"));
        address l2AssetManagerAddr = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".l2AssetManager"));

        address weth = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".pools.ethTokenPool.underlying"));
        address usdc = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".pools.usdcTokenPool.underlying"));

        // deploy impls
        l2AssetManagerImpl = new L2AssetManager();
        ethTokenPoolImpl = new ETHTokenPool(l2AssetManagerAddr, weth, owner);
        usdcTokenPoolImpl = new ERC20TokenPool(l2AssetManagerAddr, usdc, owner);

        // upgrade contracts
        _upgrade(l2AssetManagerAddr, address(l2AssetManagerImpl), "");
        _upgrade(
            ethTokenPoolAddr,
            address(ethTokenPoolImpl),
            abi.encodeWithSelector(ETHTokenPool.initialize.selector, owner, weth)
        );
        _upgrade(
            usdcTokenPoolAddr,
            address(usdcTokenPoolImpl),
            abi.encodeWithSelector(ERC20TokenPool.initialize.selector, owner, usdc)
        );

        // write json
        vm.writeJson(
            vm.toString(address(l2AssetManagerImpl)), deploymentPath, string.concat(chainKey, ".l2AssetManagerImpl")
        );
        vm.writeJson(
            vm.toString(address(ethTokenPoolImpl)), deploymentPath, string.concat(chainKey, ".pools.ethTokenPool.impl")
        );
        vm.writeJson(
            vm.toString(address(usdcTokenPoolImpl)),
            deploymentPath,
            string.concat(chainKey, ".pools.usdcTokenPool.impl")
        );
    }

    function _upgrade(address proxy, address impl, bytes memory data) internal {
        bytes32 adminSlot = vm.load(proxy, ERC1967Utils.ADMIN_SLOT);
        if (adminSlot == bytes32(0)) {
            // No admin contract: upgrade directly using interface
            ITransparentUpgradeableProxy(proxy).upgradeToAndCall(address(ethTokenPoolImpl), data);
        } else {
            ProxyAdmin admin = ProxyAdmin(address(uint160(uint256(adminSlot))));
            admin.upgradeAndCall(ITransparentUpgradeableProxy(proxy), impl, data);
        }
    }
}
