// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "../Base.s.sol";
import { NFTReceiver } from "../../src/examples/NFTReceiver.sol";
import { MikiAdapter } from "../../src/adapters/MikiAdapter.sol";
import { LayerZeroReceiver } from "../../src/adapters/LayerZeroReceiver.sol";
import { OptionsBuilder } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting

contract NFTReceiverScript is BaseScript {
    using OptionsBuilder for bytes;

    NFTReceiver public nftReceiver;
    string public uri = "ipfs://QmeuC3tFtndSF1pBTzZxUmArWiBFv3ozNhEnAPFKJp9T1E/0";

    function run() public {
        Chains[] memory deployForks = new Chains[](1);
        deployForks[0] = Chains.PolygonMumbai;

        for (uint256 i = 0; i < deployForks.length; i++) {
            Network memory network = networks[deployForks[i]];
            string memory chainKey = string.concat(".", network.name);

            address mikiReceiver =
                vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.miki.receiver"));

            _createSelectFork(deployForks[i]);

            _deployNFTReceiver(mikiReceiver);

            vm.writeJson(vm.toString(address(nftReceiver)), deploymentPath, string.concat(chainKey, ".examples.nft"));
        }
    }

    function crossChainMint(uint256 dstChainId, address to) public broadcast {
        uint256 amount = 1 ether;
        bytes memory option =
            OptionsBuilder.newOptions().addExecutorLzReceiveOption(200_000, 0).addExecutorLzComposeOption(0, 200_000, 0);

        string memory chainKey = _getChainKey(block.chainid);
        string memory targetChainKey = _getChainKey(dstChainId);
        address mikiAdapterAddr = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.miki.sender"));
        address mikiTokenAddr = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.miki.token"));
        address nftReceiverAddr = vm.parseJsonAddress(deploymentsJson, string.concat(targetChainKey, ".examples.nft"));

        MikiAdapter mikiAdapter = MikiAdapter(mikiAdapterAddr);

        bytes memory params = abi.encode(amount, option);
        bytes memory message = abi.encode(to);

        uint256 fee =
            mikiAdapter.estimateFee(broadcaster, dstChainId, nftReceiverAddr, mikiTokenAddr, message, amount, params);

        IERC20(mikiTokenAddr).approve(mikiAdapterAddr, amount);

        mikiAdapter.execCrossChainContractCallWithAsset{ value: fee * 120 / 100 }(
            msg.sender, dstChainId, nftReceiverAddr, mikiTokenAddr, message, fee * 120 / 100, amount, params
        );
    }

    function _deployNFTReceiver(address mikiReceiver) internal broadcast {
        nftReceiver = new NFTReceiver(uri, mikiReceiver);
    }
}
