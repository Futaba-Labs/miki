// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { IPool } from "@aave/core-v3/contracts/interfaces/IPool.sol";
import { IMikiReceiver } from "../interfaces/IMikiReceiver.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IAToken } from "@aave/core-v3/contracts/interfaces/IAToken.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AAVEV3Receiver is IMikiReceiver, Ownable {
    /* ----------------------------- Storage -------------------------------- */
    mapping(address token => TokenPool pool) public tokenToPool;

    /* ----------------------------- Struct -------------------------------- */
    struct TokenPool {
        address aToken;
        address pool;
    }

    /* ----------------------------- Events -------------------------------- */
    event TokenPoolSet(address token, address aToken, address pool);
    event Supply(address user, address token, uint256 amount, address aToken, uint256 aTokenAmount);

    /* ----------------------------- Errors -------------------------------- */
    error InvalidLength();
    error InvalidToken();
    error MismatchedLength();
    error ZeroAmount();

    /* ----------------------------- Constructor -------------------------------- */
    constructor(address _initialOwner) Ownable(_initialOwner) { }

    fallback() external payable { }

    receive() external payable { }

    function mikiReceive(
        uint256,
        address user,
        address token,
        uint256 amount,
        bytes calldata message
    )
        external
        payable
    {
        TokenPool memory tokenPool = tokenToPool[token];
        if (tokenPool.pool == address(0) || tokenPool.aToken == address(0)) {
            revert InvalidToken();
        }

        if (amount == 0) {
            revert ZeroAmount();
        }
        IERC20(token).approve(tokenPool.pool, amount);
        IPool(tokenPool.pool).supply(token, amount, user, 0);
        uint256 aTokenBalance = IAToken(tokenPool.aToken).balanceOf(user);
        emit Supply(user, token, amount, tokenPool.aToken, aTokenBalance);
    }

    function mikiReceiveMsg(uint256, address, bytes calldata message) external payable { }

    function setTokenPools(
        address[] calldata tokens,
        address[] calldata aTokens,
        address[] calldata pools
    )
        public
        onlyOwner
    {
        uint256 tokenLength = tokens.length;
        uint256 aTokenLength = aTokens.length;
        uint256 poolLength = pools.length;

        if (tokenLength == 0 || aTokenLength == 0 || poolLength == 0) {
            revert InvalidLength();
        }
        if (tokenLength != aTokenLength || tokenLength != poolLength) {
            revert MismatchedLength();
        }

        for (uint256 i; i < tokens.length; i++) {
            setTokenPool(tokens[i], aTokens[i], pools[i]);
        }
    }

    function setTokenPool(address token, address aToken, address pool) public onlyOwner {
        tokenToPool[token] = TokenPool(aToken, pool);
        emit TokenPoolSet(token, aToken, pool);
    }

    function getTokenPool(address token) public view returns (TokenPool memory) {
        return tokenToPool[token];
    }
}
