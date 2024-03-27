// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "../Base.s.sol";
import { EthAdapter } from "../../src/adapters/EthAdapter.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting

contract EthAdapterScript is BaseScript {
    EthAdapter private ethAdapter;

    uint256[] private chainIds;
    uint16[] private codes;

    function run() public broadcast {
        string memory chainKey = _getChainKey(block.chainid);
        address orbiterRouter =
            vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.orbiter.router"));
        ethAdapter = new EthAdapter(payable(orbiterRouter), broadcaster);

        vm.writeJson(
            vm.toString(address(ethAdapter)), deploymentPath, string.concat(chainKey, ".adapters.orbiter.sender")
        );

        Chains[] memory chains = new Chains[](1);
        chains[0] = Chains.OptimismSepolia;

        for (uint256 i = 0; i < chains.length; i++) {
            Chains chain = chains[i];
            string memory targetChainKey = _getChainKey(uint256(networks[chain].chainId));
            uint16 code =
                uint16(vm.parseJsonUint(deploymentsJson, string.concat(targetChainKey, ".adapters.orbiter.code")));
            uint256 chainId = networks[chain].chainId;
            chainIds.push(chainId);
            codes.push(code);
        }

        ethAdapter.setIdentificationCodes(chainIds, codes);
    }

    function bridgeETH(uint256 dstChainId, uint256 amount) public broadcast {
        string memory chainKey = _getChainKey(block.chainid);
        address ethAdapterAddr =
            vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".adapters.orbiter.sender"));

        ethAdapter = EthAdapter(payable(ethAdapterAddr));

        uint16 code = ethAdapter.getIdentificationCode(dstChainId);
        uint256 totalAmount = amount + code;

        ethAdapter.execCrossChainTransferAsset{ value: totalAmount }(
            broadcaster, dstChainId, broadcaster, 0xeeeEEeeEeee6B44087746554679424e322316869, 0, amount, bytes("")
        );
    }
}
