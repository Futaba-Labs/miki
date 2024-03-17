// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "../Base.s.sol";
import { AAVEV3Receiver } from "../../src/examples/AAVEV3Receiver.sol";
/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting

contract DeployAAVEV3Receiver is BaseScript {
    AAVEV3Receiver public aaveV3Receiver;
    address public aaveV3Pool = 0xcC6114B983E4Ed2737E9BD3961c9924e6216c704;
    address public USDC = 0x52D800ca262522580CeBAD275395ca6e7598C014;
    address public aUSDC = 0x4086fabeE92a080002eeBA1220B9025a27a40A49;

    function run() public broadcast {
        aaveV3Receiver = new AAVEV3Receiver(broadcaster);

        aaveV3Receiver.setTokenPool(USDC, aUSDC, aaveV3Pool);
    }
}
