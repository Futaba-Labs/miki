// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "../Base.s.sol";

import { MikiAdapter } from "../../src/adapters/MikiAdapter.sol";
import { LayerZeroReceiver } from "../../src/adapters/LayerZeroReceiver.sol";
import { OptionsBuilder } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting

contract MikiAdapterScript is BaseScript {
    using OptionsBuilder for bytes;

    MikiAdapter public mikiAdapter;

    uint256[] public chainIds;
    uint32[] public eids;
    address[] public receivers;

    function run() public {
        Chains[] memory deployForks = new Chains[](2);
        deployForks[0] = Chains.ArbitrumSepolia;
        deployForks[1] = Chains.PolygonAmoy;

        for (uint256 i = 0; i < deployForks.length; i++) {
            string memory chainKey = _getChainKey(networks[deployForks[i]].chainId);
            address token = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.miki.token"));

            _createSelectFork(deployForks[i]);

            _deployMikiAdapter(token);

            vm.writeJson(
                vm.toString(address(mikiAdapter)), deploymentPath, string.concat(chainKey, ".adapters.miki.sender")
            );
        }
    }

    function setUp() public broadcast {
        string memory chainKey = _getChainKey(block.chainid);
        address mikiAdapterAddr = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.miki.sender"));

        Chains[] memory deployForks = new Chains[](2);
        deployForks[0] = Chains.ArbitrumSepolia;
        deployForks[1] = Chains.PolygonAmoy;

        for (uint256 i = 0; i < deployForks.length; i++) {
            if (networks[deployForks[i]].chainId == block.chainid) {
                continue;
            }

            string memory targetChainKey = _getChainKey(networks[deployForks[i]].chainId);

            receivers.push(
                vm.parseJsonAddress(deploymentsJson, string.concat(targetChainKey, ".adapters.miki.receiver"))
            );
            chainIds.push(networks[deployForks[i]].chainId);
            eids.push(networks[deployForks[i]].eid);
        }

        mikiAdapter = MikiAdapter(mikiAdapterAddr);
        mikiAdapter.setEids(chainIds, eids);
        mikiAdapter.setReceivers(chainIds, receivers);
    }

    function bridgeOFT(uint256 dstChainId, address to, uint256 amount) public broadcast {
        bytes memory option = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200_000, 0);

        string memory chainKey = _getChainKey(block.chainid);
        address mikiAdapterAddr = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.miki.sender"));
        address mikiTokenAddr = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.miki.token"));

        mikiAdapter = MikiAdapter(mikiAdapterAddr);

        bytes memory params = abi.encode(amount, option);

        uint256 fee = mikiAdapter.estimateFee(broadcaster, dstChainId, to, mikiTokenAddr, bytes(""), amount, params);

        IERC20(mikiTokenAddr).approve(mikiAdapterAddr, amount);

        mikiAdapter.execCrossChainTransferAsset{ value: fee }(
            msg.sender, dstChainId, to, mikiTokenAddr, amount, fee, params
        );
    }

    function _deployMikiAdapter(address token) internal broadcast {
        mikiAdapter = new MikiAdapter(token, broadcaster);
    }
}
