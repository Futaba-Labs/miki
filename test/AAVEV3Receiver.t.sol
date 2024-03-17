// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { console2 } from "forge-std/src/console2.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { AAVEV3Receiver } from "../src/examples/AAVEV3Receiver.sol";
import { ATokenMock } from "./mock/ATokenMock.sol";
import { AAVEV3PoolMock } from "./mock/AAVEV3PoolMock.sol";
import { ERC20Mock } from "./mock/ERC20Mock.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AAVEV3ReceiverTest is PRBTest, StdCheats {
    address public owner;
    AAVEV3Receiver public receiver;
    ATokenMock public aToken;
    AAVEV3PoolMock public pool;
    ERC20Mock public erc20;
    ERC20Mock public anotherErc20;

    event TokenPoolSet(address token, address aToken, address pool);
    event Supply(address user, address token, uint256 amount, address aToken, uint256 aTokenAmount);

    function setUp() public virtual {
        owner = msg.sender;

        aToken = new ATokenMock("aToken", "aToken");
        pool = new AAVEV3PoolMock(address(aToken));
        receiver = new AAVEV3Receiver(owner);
        erc20 = new ERC20Mock("erc20", "erc20");
        anotherErc20 = new ERC20Mock("anotherErc20", "anotherErc20");

        erc20.mint(owner, 1000 ether);
        anotherErc20.mint(owner, 1000 ether);

        vm.prank(owner);
        receiver.setTokenPool(address(erc20), address(aToken), address(pool));
    }

    function test_MikiReceive() public {
        vm.prank(owner);
        IERC20(erc20).transfer(address(receiver), 100 ether);
        vm.expectEmit(true, true, true, true);
        emit Supply(owner, address(erc20), 100 ether, address(aToken), 100 ether);
        receiver.mikiReceive(1, owner, address(erc20), 100 ether, bytes(""));

        assertEq(erc20.balanceOf(owner), 900 ether);
        assertEq(aToken.balanceOf(owner), 100 ether);
    }

    function test_InvalidToken() public {
        bytes4 selector = bytes4(keccak256("InvalidToken()"));
        vm.expectRevert(selector);
        receiver.mikiReceive(1, owner, address(anotherErc20), 100, bytes(""));
    }

    function test_InsufficientAmount() public {
        bytes4 selector = bytes4(keccak256("ZeroAmount()"));
        vm.expectRevert(selector);
        receiver.mikiReceive(1, owner, address(erc20), 0, bytes(""));
    }

    function test_SetTokenPool() public {
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit TokenPoolSet(address(erc20), address(aToken), address(pool));
        receiver.setTokenPool(address(erc20), address(aToken), address(pool));
        vm.stopPrank();

        assertEq(receiver.getTokenPool(address(erc20)).pool, address(pool));
        assertEq(receiver.getTokenPool(address(erc20)).aToken, address(aToken));
    }
}
