// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { IPool } from "@aave/core-v3/contracts/interfaces/IPool.sol";
import { IMikiAppReceiver } from "../interfaces/IMikiAppReceiver.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IAToken } from "@aave/core-v3/contracts/interfaces/IAToken.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { GelatoRelayContextERC2771 } from "@gelatonetwork/relay-context/contracts/GelatoRelayContextERC2771.sol";
import { IAllowanceTransfer } from "../interfaces/IAllowanceTransfer.sol";
import { ISampleAMM } from "../interfaces/ISampleAMM.sol";
import { IWETH } from "../interfaces/IWETH.sol";

contract AAVEV3Receiver is IMikiAppReceiver, Ownable, GelatoRelayContextERC2771 {
    /* ----------------------------- Storage -------------------------------- */
    IAllowanceTransfer public immutable permit2;
    ISampleAMM public immutable amm;
    address public immutable mikiReceiver;
    address public weth;
    mapping(address => TokenPool) public tokenToPool;

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
    error InvalidSpender();
    error NotMikiReceiver();

    /* ----------------------------- Constructor -------------------------------- */
    constructor(
        address _initialOwner,
        address _permit2,
        address _amm,
        address _mikiReceiver,
        address _weth
    )
        Ownable(_initialOwner)
    {
        permit2 = IAllowanceTransfer(_permit2);
        amm = ISampleAMM(_amm);
        mikiReceiver = _mikiReceiver;
        weth = _weth;
    }

    /* ----------------------------- Modifier -------------------------------- */
    modifier onlyMikiReceiver() {
        if (msg.sender != mikiReceiver) revert NotMikiReceiver();
        _;
    }

    /* ----------------------------- External Functions -------------------------------- */
    function mikiReceive(
        uint256,
        address user,
        address token,
        uint256 amount,
        bytes calldata message
    )
        external
        payable
        onlyMikiReceiver
    {
        address underlyingToken = token;
        if (underlyingToken == address(0)) {
            underlyingToken = weth;
        }
        if (message.length > 0) {
            underlyingToken = abi.decode(message, (address));
        }

        TokenPool memory tokenPool = tokenToPool[underlyingToken];
        if (tokenPool.pool == address(0) || tokenPool.aToken == address(0)) {
            revert InvalidToken();
        }

        uint256 amountIn = amount;
        if (underlyingToken != token) {
            if (underlyingToken != weth) {
                IERC20(token).approve(address(amm), amount);
                amountIn = amm.swap(token, amount);
            } else {
                IWETH(payable(weth)).deposit{ value: amount }();
            }
        }

        IERC20(underlyingToken).approve(tokenPool.pool, amountIn);
        IPool(tokenPool.pool).supply(underlyingToken, amountIn, user, 0);
        uint256 aTokenBalance = IAToken(tokenPool.aToken).balanceOf(user);

        emit Supply(user, token, amount, tokenPool.aToken, aTokenBalance);
    }

    function withdrawWithRelay(
        address token,
        uint256 amount,
        IAllowanceTransfer.PermitSingle calldata permitSingle,
        bytes calldata signature
    )
        external
        payable
        onlyGelatoRelayERC2771
    {
        address sender = _getMsgSender();
        TokenPool memory tokenPool = tokenToPool[token];
        if (tokenPool.pool == address(0) || tokenPool.aToken == address(0)) {
            revert InvalidToken();
        }

        if (permitSingle.spender != address(this)) revert InvalidSpender();
        permit2.permit(sender, permitSingle, signature);
        permit2.transferFrom(sender, address(this), uint160(amount), tokenPool.aToken);
        _withdraw(sender, token, tokenPool, amount);
        _transferRelayFee();
    }

    function withdrawWithPermit(
        address token,
        uint256 amount,
        IAllowanceTransfer.PermitSingle calldata permitSingle,
        bytes calldata signature
    )
        external
        payable
    {
        address sender = msg.sender;
        TokenPool memory tokenPool = tokenToPool[token];
        if (tokenPool.pool == address(0) || tokenPool.aToken == address(0)) {
            revert InvalidToken();
        }

        if (permitSingle.spender != address(this)) revert InvalidSpender();
        permit2.permit(msg.sender, permitSingle, signature);
        permit2.transferFrom(sender, address(this), uint160(amount), tokenPool.aToken);
        _withdraw(sender, token, tokenPool, amount);
    }

    function withdraw(address token, uint256 amount) external payable {
        address sender = msg.sender;
        TokenPool memory tokenPool = tokenToPool[token];
        if (tokenPool.pool == address(0) || tokenPool.aToken == address(0)) {
            revert InvalidToken();
        }
        IAToken(tokenPool.aToken).transferFrom(sender, address(this), amount);
        _withdraw(sender, token, tokenPool, amount);
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

    /* ----------------------------- Internal Functions -------------------------------- */
    function _withdraw(
        address sender,
        address token,
        TokenPool memory tokenPool,
        uint256 amount
    )
        internal
        returns (uint256)
    {
        IAToken(tokenPool.aToken).approve(tokenPool.pool, amount);
        return IPool(tokenPool.pool).withdraw(token, amount, address(this));
    }

    fallback() external payable { }

    receive() external payable { }
}
