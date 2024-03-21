// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { BaseScript } from "../Base.s.sol";
import { AAVEV3Receiver } from "../../src/examples/AAVEV3Receiver.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting

contract SupplyUSDC is BaseScript {
    AAVEV3Receiver public aaveV3Receiver = AAVEV3Receiver(payable(0x8dF70EF054fE8d5AFA35B34fEE02d5Aec5720c31));
    address public USDC = 0x52D800ca262522580CeBAD275395ca6e7598C014;

    function run() public broadcast {
        IERC20(USDC).transfer(address(aaveV3Receiver), 10_000_000);
        aaveV3Receiver.mikiReceive(1, broadcaster, USDC, 10_000_000, bytes(""));
    }
}
