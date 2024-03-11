// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { console2 } from "forge-std/src/console2.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { L2AssetManager } from "../src/L2AssetManager.sol";
import { ETHTokenPool } from "../src/pools/ETHTokenPool.sol";
import { ITokenPool } from "../src/interfaces/ITokenPool.sol";

contract L2AssetManagerTest is PRBTest, StdCheats {
    address public owner;
    ProxyAdmin public mikiProxyAdmin;
    L2AssetManager public l2AssetManager;
    ETHTokenPool public ethTokenPool;

    // bytes32 privateKey = 0x1234567812345678123456781234567812345678123456781234567812345678;
    // address account = cheats.addr(uint256(privateKey));

    /// @dev A function invoked before each test case is run.
    function setUp() public virtual {
        // Instantiate the contract-under-test.
        owner = msg.sender;
        mikiProxyAdmin = new ProxyAdmin(owner);
        L2AssetManager l2AssetManagerImplementation = new L2AssetManager();
        l2AssetManager = L2AssetManager(
            address(
                new TransparentUpgradeableProxy(
                    address(l2AssetManagerImplementation),
                    address(mikiProxyAdmin),
                    abi.encodeWithSelector(L2AssetManager.initialize.selector, owner)
                )
            )
        );
        ethTokenPool = new ETHTokenPool(owner, address(l2AssetManager), owner);

        // Set the native token pool.
        vm.prank(owner);
        l2AssetManager.setNativeTokenPool(address(ethTokenPool));
    }

    function test_Deposit() external {
        // TODO Implement this test.
    }

    function test_DepositETH() external {
        // Deposit 1 ETH to the native token pool.
        l2AssetManager.depositETH{ value: 1 ether }(1 ether);
        assertEq(ethTokenPool.totalAmount(), 1 ether);
        uint256 balance = l2AssetManager.getDeposit(address(ethTokenPool), address(this));
        assertEq(balance, 1 ether);
    }

    function test_DepositETHInsufficientAmount() external {
        // Deposit 0 ETH to the native token pool.
        bytes4 selector = bytes4(keccak256("InsufficientAmount()"));
        vm.expectRevert(selector);
        l2AssetManager.depositETH{ value: 0 }(0);
        assertEq(ethTokenPool.totalAmount(), 0);
        uint256 balance = l2AssetManager.getDeposit(address(ethTokenPool), address(this));
        assertEq(balance, 0);
    }

    function test_Withdraw() external {
        // TODO Implement this test.
    }

    function test_WithdrawETH() external {
        // Deposit 1 ETH to the native token pool.
        vm.prank(owner);
        l2AssetManager.depositETH{ value: 1 ether }(1 ether);
        assertEq(ethTokenPool.totalAmount(), 1 ether);

        // Withdraw 1 ETH from the native token pool.
        vm.prank(owner);
        l2AssetManager.withdrawETH(1 ether, owner);
        assertEq(ethTokenPool.totalAmount(), 0);
    }

    function test_AddDepositsNotWhitelistedTokenPool() external {
        bytes4 selector = bytes4(keccak256("NotWhitelistedTokenPool()"));
        vm.expectRevert(selector);
        l2AssetManager.addDeposits(address(ethTokenPool), address(this), 1 ether);
    }

    function test_RemoveDepositsNotWhitelistedTokenPool() external {
        bytes4 selector = bytes4(keccak256("NotWhitelistedTokenPool()"));
        vm.expectRevert(selector);
        l2AssetManager.removeDeposits(address(ethTokenPool), address(this), 1 ether);
    }

    function test_SetNativeTokenPool() external {
        vm.prank(owner);
        l2AssetManager.setNativeTokenPool(address(ethTokenPool));
        assertEq(l2AssetManager.getNativeTokenPool(), address(ethTokenPool));
    }

    function test_SetTokenPoolWhitelists() external {
        // TODO Implement this test.
    }
}
