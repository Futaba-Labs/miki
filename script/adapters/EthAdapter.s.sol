// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "../Base.s.sol";
import { EthAdapter } from "../../src/adapters/EthAdapter.sol";
import { LayerZeroAdapter } from "../../src/adapters/LayerZeroAdapter.sol";
import { OptionsBuilder } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import { MikiRouterReceiver } from "../../src/adapters/MikiRouterReceiver.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting

contract EthAdapterScript is BaseScript {
    using OptionsBuilder for bytes;

    EthAdapter private ethAdapter;
    LayerZeroAdapter private lzAdapter;
    MikiRouterReceiver private mikiRouterReceiver;

    uint256[] private chainIds;
    uint32[] private eids;
    uint16[] private codes;

    function run() public broadcast {
        Chains[] memory chains = new Chains[](1);
        chains[0] = Chains.OptimismSepolia;

        for (uint256 i = 0; i < chains.length; i++) {
            Chains chain = chains[i];
            string memory targetChainKey = _getChainKey(uint256(networks[chain].chainId));
            uint16 code =
                uint16(vm.parseJsonUint(deploymentsJson, string.concat(targetChainKey, ".adapters.orbiter.code")));
            uint256 chainId = networks[chain].chainId;
            uint32 eid = networks[chain].eid;
            chainIds.push(chainId);
            eids.push(eid);
            codes.push(code);
        }

        string memory chainKey = _getChainKey(block.chainid);
        address router = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.eth.router"));
        address lzGateway = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.layerZero.gateway"));
        lzAdapter = new LayerZeroAdapter(broadcaster, lzGateway, chainIds, eids);

        ethAdapter = new EthAdapter(payable(router), payable(router), address(lzAdapter), broadcaster);

        vm.writeJson(vm.toString(address(ethAdapter)), deploymentPath, string.concat(chainKey, ".adapters.eth.sender"));
        vm.writeJson(
            vm.toString(address(lzAdapter)), deploymentPath, string.concat(chainKey, ".adapters.layerZero.sender")
        );

        ethAdapter.setIdentificationCodes(chainIds, codes);
    }

    function deployMikiRouterReceiver() public broadcast {
        string memory chainKey = _getChainKey(block.chainid);
        address router = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.eth.router"));
        address mikiReceiverAddr =
            vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.mikiReceiver"));
        mikiRouterReceiver = new MikiRouterReceiver(router, mikiReceiverAddr, broadcaster);
        vm.writeJson(
            vm.toString(address(mikiRouterReceiver)), deploymentPath, string.concat(chainKey, ".adapters.eth.receiver")
        );
    }

    function bridgeETH(uint256 dstChainId, uint256 amount) public broadcast {
        string memory chainKey = _getChainKey(block.chainid);
        string memory dstChainKey = _getChainKey(dstChainId);
        address ethAdapterAddr = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.eth.sender"));
        address nftReceiver = vm.parseJsonAddress(deploymentsJson, string.concat(dstChainKey, ".examples.nft"));
        ethAdapter = EthAdapter(payable(ethAdapterAddr));

        // uint16 code = ethAdapter.getIdentificationCode(dstChainId);
        uint256 totalAmount = amount;

        bytes memory message = abi.encode(broadcaster);

        // ethAdapter.execCrossChainTransferAsset{ value: totalAmount }(
        //     broadcaster, dstChainId, broadcaster, 0xeeeEEeeEeee6B44087746554679424e322316869, 0, amount, message
        // );

        ethAdapter.execCrossChainContractCallWithAsset{ value: totalAmount }(
            broadcaster, dstChainId, nftReceiver, address(0), message, 0, amount, bytes("")
        );
    }

    function crossChainMint(uint256 dstChainId, address to) public broadcast {
        bytes memory option = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200_000, 0);

        string memory chainKey = _getChainKey(block.chainid);
        string memory dstChainKey = _getChainKey(dstChainId);

        address ethAdapterAddr = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.eth.sender"));
        address nftReceiver = vm.parseJsonAddress(deploymentsJson, string.concat(dstChainKey, ".examples.nft"));

        ethAdapter = EthAdapter(payable(ethAdapterAddr));

        bytes memory params = abi.encode(option, bytes(""));
        bytes memory message = abi.encode(to);

        uint256 fee = ethAdapter.estimateFee(broadcaster, dstChainId, nftReceiver, address(0), message, 0, params);

        ethAdapter.execCrossChainContractCall{ value: fee }(broadcaster, dstChainId, nftReceiver, message, fee, params);
    }
}
