// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "../Base.s.sol";

import { MikiTestToken } from "../../src/adapters/MikiTestToken.sol";
import { SendParam } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import { OptionsBuilder } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import { MessagingFee } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting

contract MikiTokenScript is BaseScript {
    using OptionsBuilder for bytes;

    string public constant name = "Miki";
    string public constant symbol = "MIKI";
    string public constant obj = "miki token address";

    address public owner;
    MikiTestToken public miki;

    Deployment[] public deployments;

    struct Deployment {
        Chains chain;
        uint32 eid;
        address miki;
    }

    function run() public {
        Chains[] memory deployForks = new Chains[](2);
        deployForks[0] = Chains.ArbitrumSepolia;
        deployForks[1] = Chains.PolygonAmoy;

        for (uint256 i = 0; i < deployForks.length; i++) {
            string memory chainKey = string.concat(".", networks[deployForks[i]].name);
            string memory gatewayKey = string.concat(chainKey, ".adapters.layerZero.gateway");
            address gateway = vm.parseJsonAddress(deploymentsJson, gatewayKey);

            _createSelectFork(deployForks[i]);

            address mikiAddress = _deployMiki(gateway);
            string memory mikiKey = string.concat(chainKey, ".adapters.miki.token");
            vm.writeJson(vm.toString(mikiAddress), deploymentPath, mikiKey);

            Network memory network = networks[deployForks[i]];
            deployments.push(Deployment(deployForks[i], network.eid, mikiAddress));
        }
    }

    function mint(address to, uint256 amount) public broadcast {
        string memory chainKey = _getChainKey(block.chainid);
        string memory mikiKey = string.concat(chainKey, ".adapters.miki.token");
        address mikiToken = vm.parseJsonAddress(deploymentsJson, mikiKey);

        MikiTestToken(mikiToken).mint(to, amount);
    }

    function bridgeOFT(uint256 dstChainId, address to, uint256 amount) public broadcast {
        bytes memory option = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200_000, 0);

        string memory srcChainKey = _getChainKey(block.chainid);
        address mikiAddr = vm.parseJsonAddress(deploymentsJson, string.concat(srcChainKey, ".adapters.miki.token"));

        miki = MikiTestToken(mikiAddr);

        Network memory network = _getNetwork(dstChainId);

        SendParam memory sendParam =
            SendParam(network.eid, bytes32(uint256(uint160(to))), amount, amount, option, "", "");

        MessagingFee memory msgFee = miki.quoteSend(sendParam, false);

        miki.send{ value: msgFee.nativeFee }(sendParam, msgFee, msg.sender);
    }

    function _deployMiki(address gateway) internal broadcast returns (address) {
        miki = new MikiTestToken(name, symbol, gateway, broadcaster);
        return address(miki);
    }
}
