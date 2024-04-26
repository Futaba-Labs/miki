// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "./Base.s.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { L2AssetManager } from "../src/L2AssetManager.sol";
import { ETHTokenPool } from "../src/pools/ETHTokenPool.sol";
import { ERC20TokenPool } from "../src/pools/ERC20TokenPool.sol";
import { OptionsBuilder } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import { EthAdapter } from "../src/adapters/EthAdapter.sol";
import { NFTReceiver } from "../src/examples/NFTReceiver.sol";
import { AAVEV3Receiver } from "../src/examples/AAVEV3Receiver.sol";
import { console2 } from "forge-std/src/console2.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting

contract SendTransactionScript is BaseScript {
    using OptionsBuilder for bytes;

    // Miki Contracts
    L2AssetManager public l2AssetManager;
    L2AssetManager public l2AssetManagerImpl;
    ETHTokenPool public ethTokenPool;
    ERC20TokenPool public usdcTokenPool;

    // Miki Adapters
    EthAdapter public ethAdapter;

    // Miki Examples
    NFTReceiver public nftReceiver;
    AAVEV3Receiver public aaveV3Receiver;

    // Other params
    string public chainKey;

    function depositETH(uint256 amount) public broadcast {
        _readAddresses();
        l2AssetManager.depositETH{ value: amount }(amount);
    }

    function withdrawETH(uint256 amount) public broadcast {
        _readAddresses();
        l2AssetManager.withdrawETH(amount, broadcaster);
    }

    function depositERC20(address token, address tokenPool, uint256 amount) public broadcast {
        _readAddresses();
        IERC20(token).approve(address(l2AssetManager), amount);
        l2AssetManager.deposit(token, tokenPool, amount);
    }

    function crossChainMint(uint256 dstChainId, address to) public broadcast {
        _readAddresses();
        bytes memory option = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200_000, 0);

        string memory dstChainKey = _getChainKey(dstChainId);
        address nftReceiver = vm.parseJsonAddress(deploymentsJson, string.concat(dstChainKey, ".examples.nft"));

        bytes memory params = abi.encode(option, bytes(""));
        bytes memory message = abi.encode(to);

        uint256 fee = ethAdapter.estimateFee(broadcaster, dstChainId, nftReceiver, address(0), message, 0, params);

        ethTokenPool.crossChainContractCall(dstChainId, nftReceiver, message, fee, params);
    }

    function crossChainETHComposableBridge(
        uint256 dstChainId,
        address to,
        uint256 amount,
        string calldata name
    )
        public
        broadcast
    {
        _readAddresses();
        string memory dstChainKey = _getChainKey(dstChainId);

        address nftReceiver = vm.parseJsonAddress(deploymentsJson, string.concat(dstChainKey, ".examples.nft"));
        address aaveV3ReceiverAddr =
            vm.parseJsonAddress(deploymentsJson, string.concat(dstChainKey, ".examples.aave.receiver"));
        address weth =
            vm.parseJsonAddress(deploymentsJson, string.concat(dstChainKey, ".examples.aave.weth.underlying"));
        if (keccak256(abi.encodePacked(name)) == keccak256("nft")) {
            bytes memory message = abi.encode(to);
            ethTokenPool.crossChainContractCallWithAsset(dstChainId, nftReceiver, message, 0, amount, bytes(""));
        }
        if (keccak256(abi.encodePacked(name)) == keccak256("aave")) {
            bytes memory message = abi.encode(weth);
            ethTokenPool.crossChainContractCallWithAsset(dstChainId, aaveV3ReceiverAddr, message, 0, amount, bytes(""));
        }
    }

    function _readAddresses() internal {
        chainKey = _getChainKey(block.chainid);
        address l2AssetManagerAddr =
            vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".l2AssetManagerProxy"));
        address ethTokenPoolAddr =
            vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".pools.ethTokenPool.proxy"));
        address usdcTokenPoolAddr =
            vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".pools.usdcTokenPool.proxy"));
        address ethAdapterAddr = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.eth.sender"));

        l2AssetManager = L2AssetManager(l2AssetManagerAddr);
        ethTokenPool = ETHTokenPool(payable(ethTokenPoolAddr));
        usdcTokenPool = ERC20TokenPool(payable(usdcTokenPoolAddr));
        ethAdapter = EthAdapter(payable(ethAdapterAddr));
    }
}
