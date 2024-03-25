// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "../Base.s.sol";
import { AAVEV3Receiver } from "../../src/examples/AAVEV3Receiver.sol";
import { OptionsBuilder } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { MikiAdapter } from "../../src/adapters/MikiAdapter.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting

contract AAVEV3ReceiverScript is BaseScript {
    using OptionsBuilder for bytes;

    AAVEV3Receiver public aaveV3Receiver;

    function run() public {
        Chains[] memory deployForks = new Chains[](1);
        deployForks[0] = Chains.PolygonMumbai;

        for (uint256 i = 0; i < deployForks.length; i++) {
            Network memory network = networks[deployForks[i]];
            string memory chainKey = string.concat(".", network.name);

            address amm = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".examples.amm.pool"));
            address permit2 = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".examples.aave.permit2"));
            address mikiReceiver =
                vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.miki.receiver"));

            _createSelectFork(deployForks[i]);

            _deployAAVEV3Receiver(permit2, amm, mikiReceiver);

            vm.writeJson(
                vm.toString(address(aaveV3Receiver)), deploymentPath, string.concat(chainKey, ".examples.aave.receiver")
            );
        }
    }

    function setTokenPool(string memory tokenName) public broadcast {
        string memory chainKey = _getChainKey(block.chainid);
        string memory tokenKey = string.concat(chainKey, ".examples.aave.", tokenName);

        address underlyingToken = vm.parseJsonAddress(deploymentsJson, string.concat(tokenKey, ".underlying"));
        address aToken = vm.parseJsonAddress(deploymentsJson, string.concat(tokenKey, ".aToken"));
        address pool = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".examples.aave.pool"));

        address aaveV3ReceiverAddr =
            vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".examples.aave.receiver"));

        AAVEV3Receiver(payable(aaveV3ReceiverAddr)).setTokenPool(underlyingToken, aToken, pool);
    }

    function crossChainDeposit(uint256 dstChainId, string memory tokenName, uint256 amount) public broadcast {
        string memory chainKey = _getChainKey(block.chainid);
        string memory targetChainKey = _getChainKey(dstChainId);
        string memory tokenKey = string.concat(targetChainKey, ".examples.aave.", tokenName);

        address underlyingToken = vm.parseJsonAddress(deploymentsJson, string.concat(tokenKey, ".underlying"));
        address aaveV3ReceiverAddr =
            vm.parseJsonAddress(deploymentsJson, string.concat(targetChainKey, ".examples.aave.receiver"));
        address mikiAdapterAddr = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.miki.sender"));
        address mikiTokenAddr = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.miki.token"));

        MikiAdapter mikiAdapter = MikiAdapter(mikiAdapterAddr);

        bytes memory option =
            OptionsBuilder.newOptions().addExecutorLzReceiveOption(200_000, 0).addExecutorLzComposeOption(0, 500_000, 0);

        bytes memory params = abi.encode(amount, option);
        bytes memory message = abi.encode(underlyingToken);

        uint256 fee =
            mikiAdapter.estimateFee(broadcaster, dstChainId, aaveV3ReceiverAddr, mikiTokenAddr, message, amount, params);

        IERC20(mikiTokenAddr).approve(mikiAdapterAddr, amount);

        mikiAdapter.execCrossChainContractCallWithAsset{ value: fee * 120 / 100 }(
            broadcaster, dstChainId, aaveV3ReceiverAddr, mikiTokenAddr, message, fee * 120 / 100, amount, params
        );
    }

    function _deployAAVEV3Receiver(address permit2, address amm, address mikiReceiver) internal broadcast {
        aaveV3Receiver = new AAVEV3Receiver(broadcaster, permit2, amm, mikiReceiver);
    }
}
