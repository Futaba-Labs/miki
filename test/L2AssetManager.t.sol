// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { console2 } from "forge-std/src/console2.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { L2AssetManager } from "../src/L2AssetManager.sol";
import { ETHTokenPool } from "../src/pools/ETHTokenPool.sol";
import { ERC20TokenPoolMock } from "./mock/ERC20TokenPoolMock.sol";
import { ERC20Mock } from "./mock/ERC20Mock.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract L2AssetManagerTest is PRBTest, StdCheats {
    address public owner;
    address public underlyingToken;
    address public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address[] public tokenPools;
    bool[] public whitelists = [true];
    ProxyAdmin public mikiProxyAdmin;
    L2AssetManager public l2AssetManager;
    ETHTokenPool public ethTokenPool;
    ERC20TokenPoolMock public erc20TokenPool;

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
        ethTokenPool = new ETHTokenPool(owner, address(l2AssetManager), owner, weth);

        ERC20Mock erc20 = new ERC20Mock("Test", "TEST");
        erc20.mint(address(this), 100 ether);
        underlyingToken = address(erc20);
        erc20TokenPool = new ERC20TokenPoolMock(owner, address(l2AssetManager), underlyingToken, owner);

        // Set the native token pool.
        vm.prank(owner);
        l2AssetManager.setNativeTokenPool(address(ethTokenPool));

        // Set the erc20 token pool.
        vm.prank(owner);
        tokenPools.push(address(erc20TokenPool));
        l2AssetManager.setTokenPoolWhitelists(tokenPools, whitelists);
    }

    function test_Deposit() external {
        // Deposit 1 TEST to the erc20 token pool.
        uint256 amount = 1 ether;
        IERC20(underlyingToken).approve(address(l2AssetManager), amount);
        l2AssetManager.deposit(underlyingToken, address(erc20TokenPool), amount);
        assertEq(erc20TokenPool.totalAmount(), amount);
        uint256 balance = l2AssetManager.getDeposit(address(erc20TokenPool), address(this));
        assertEq(balance, amount);
        ETHTokenPool.BatchInfo[] memory batches = erc20TokenPool.getBatches();
        assertEq(batches.length, 1);
        assertEq(batches[0].user, address(this));
        assertEq(batches[0].amount, amount);
    }

    function test_DepositETH() external {
        // Deposit 1 ETH to the native token pool.
        l2AssetManager.depositETH{ value: 1 ether }(1 ether);
        assertEq(ethTokenPool.totalAmount(), 1 ether);
        uint256 balance = l2AssetManager.getDeposit(address(ethTokenPool), address(this));
        assertEq(balance, 1 ether);
        ETHTokenPool.BatchInfo[] memory batches = ethTokenPool.getBatches();
        assertEq(batches.length, 1);
        assertEq(batches[0].user, address(this));
        assertEq(batches[0].amount, 1 ether);
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
        // Deposit 1 TEST to the erc20 token pool.
        uint256 amount = 1 ether;
        IERC20(underlyingToken).approve(address(l2AssetManager), amount);
        l2AssetManager.deposit(underlyingToken, address(erc20TokenPool), amount);

        assertEq(erc20TokenPool.totalAmount(), amount);

        // Withdraw 1 TEST from the erc20 token pool.
        l2AssetManager.withdraw(address(erc20TokenPool), amount, owner);
        assertEq(erc20TokenPool.totalAmount(), 0);
        assertEq(l2AssetManager.getDeposit(address(erc20TokenPool), address(this)), 0);
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
        assertEq(l2AssetManager.getDeposit(address(ethTokenPool), address(this)), 0);
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
        vm.prank(owner);
        l2AssetManager.setTokenPoolWhitelists(tokenPools, whitelists);
        assertEq(l2AssetManager.getTokenPoolWhitelist(address(erc20TokenPool)), true);
    }
}
