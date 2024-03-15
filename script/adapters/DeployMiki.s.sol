// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "../Base.s.sol";

import { ETHTokenPool } from "../../src/pools/ETHTokenPool.sol";
import { MikiTestToken } from "../../src/adapters/MikiTestToken.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeployMiki is BaseScript {
    string public constant name = "Miki";
    string public constant symbol = "MIKI";
    address public lzEndpoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    address public owner;
    MikiTestToken public miki;

    function run() public broadcast {
        owner = broadcaster;
        miki = new MikiTestToken(name, symbol, lzEndpoint, owner);
    }
}
