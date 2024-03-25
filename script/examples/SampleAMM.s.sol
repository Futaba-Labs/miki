// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "../Base.s.sol";
import { SampleAMM } from "../../src/examples/SampleAMM.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting

contract SampleAMMScript is BaseScript {
    SampleAMM public sampleAMM;

    function run() public {
        Chains[] memory deployForks = new Chains[](1);
        deployForks[0] = Chains.PolygonMumbai;

        for (uint256 i = 0; i < deployForks.length; i++) {
            Network memory network = networks[deployForks[i]];
            string memory chainKey = string.concat(".", network.name);
            string memory ammKey = string.concat(chainKey, ".examples.amm.pool");

            address token0 = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".examples.amm.token0"));
            address token1 = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".examples.amm.token1"));

            _createSelectFork(deployForks[i]);

            _deploySampleAMM(token0, token1);

            vm.writeJson(vm.toString(address(sampleAMM)), deploymentPath, ammKey);
        }
    }

    function addLiquidity(uint256 token0Amount, uint256 token1Amount) public broadcast {
        string memory chainKey = _getChainKey(block.chainid);

        address amm = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".examples.amm.pool"));
        address token0 = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".examples.amm.token0"));
        address token1 = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".examples.amm.token1"));

        sampleAMM = SampleAMM(amm);

        IERC20(token0).approve(address(sampleAMM), token0Amount);
        IERC20(token1).approve(address(sampleAMM), token1Amount);

        sampleAMM.addLiquidity(token0Amount, token1Amount);
    }

    function swap(address tokenIn, uint256 amountIn) public broadcast {
        string memory chainKey = _getChainKey(block.chainid);
        address amm = vm.parseJsonAddress(deploymentsJson, string.concat(chainKey, ".examples.amm.pool"));
        sampleAMM = SampleAMM(amm);

        IERC20(tokenIn).approve(address(sampleAMM), amountIn);

        sampleAMM.swap(tokenIn, amountIn);
    }

    function _deploySampleAMM(address token0, address token1) internal broadcast {
        sampleAMM = new SampleAMM(token0, token1);
    }
}
