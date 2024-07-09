// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IL2BridgeAdapter } from "../interfaces/IL2BridgeAdapter.sol";
import { ITokenMessenger } from "../interfaces/ITokenMessenger.sol";

/**
 * @title CCTPAdapter
 * @notice CCTPAdapter is an adapter contract for using CCTP
 */
contract CCTPAdapter is IL2BridgeAdapter, Ownable {
    using SafeERC20 for IERC20;

    /* ----------------------------- Storage -------------------------------- */
    ITokenMessenger public immutable tokenMessenger;

    /// @dev The token will be burned on the source chain and minted on the destination chain, basically $USDC or $EURC
    IERC20 public immutable token;

    /// @notice Mapping: ChainId => MintRecipient
    /// @dev The mint recipient is the address that will receive the minted token on the destination chain
    mapping(uint32 domain => address recipient) public mintRecipients;

    /// @notice Mapping: ChainId => Domain
    /// @dev A domain is a Circle-issued identifier for a blockchain where CCTP contracts are deployed
    mapping(uint256 chainId => uint32 domain) public domains;

    /* ----------------------------- Events -------------------------------- */
    /// @notice Emitted when the chain id is set
    event SetChainId(uint256 chainId, uint16 chainIdUint16);

    /// @notice Emitted when the cctpSend is made
    event CCTPSend(address indexed sender, uint256 dstChainId, address indexed recipient);

    /// @notice Emitted when the depositForBurn is made
    event DepositForBurn(address indexed sender, uint32 indexed domain);

    /// @notice Emitted when the length of the chain ids and domains does not match
    error MismatchedLength();

    /* ----------------------------- Errors -------------------------------- */
    /// @notice Emitted when the length of the chain ids and endpoint ids does not match
    error MismatchLength();

    /// @notice Emitted when the length of the chain ids and endpoint ids does not match
    error InvalidLength();

    /// @notice Emitted when the network is not supported
    error NotSupportedNetwork();

    /// @notice Emitted when the token is not supported
    error NotSupportedToken();

    /* ----------------------------- Constructor -------------------------------- */
    /**
     * @notice Constructor
     * @param _initialOwner The address of the initial owner of the contract
     * @param _tokenMessenger The address of the token messenger
     * @param _token The address of the token
     */
    constructor(address _initialOwner, address _tokenMessenger, address _token) Ownable(_initialOwner) {
        tokenMessenger = ITokenMessenger(_tokenMessenger);
        token = IERC20(_token);

        uint256[] memory chainIds = new uint256[](6);
        chainIds[0] = 11_155_111; // Sepolia
        chainIds[1] = 43_113; // Avalanche Fuji
        chainIds[2] = 11_155_420; // OP Sepolia
        chainIds[3] = 421_614; // Arbitrum Sepolia
        chainIds[4] = 84_532; // Base Sepolia
        chainIds[5] = 80_002; // Polygon Amoy
        uint32[] memory domainsArray = new uint32[](6);
        domainsArray[0] = 0;
        domainsArray[1] = 1;
        domainsArray[2] = 2;
        domainsArray[3] = 3;
        domainsArray[4] = 6;
        domainsArray[5] = 7;
        _setChainIdsToDomains(chainIds, domainsArray);
    }

    /* ----------------------------- Functions -------------------------------- */

    function execCrossChainContractCall(
        address sender,
        uint256 dstChainId,
        address recipient,
        bytes calldata message,
        uint256 fee,
        bytes calldata params
    )
        external
        payable
    { }

    function execCrossChainContractCallWithAsset(
        address sender,
        uint256 dstChainId,
        address recipient,
        address asset,
        bytes calldata message,
        uint256 fee,
        uint256 amount,
        bytes calldata params
    )
        external
        payable
    { }

    function execCrossChainTransferAsset(
        address sender,
        uint256 dstChainId,
        address recipient,
        address asset,
        uint256 amount,
        uint256 fee,
        bytes calldata params
    )
        external
        payable
    {
        if (asset != address(token)) {
            revert NotSupportedToken();
        }
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        IERC20(token).approve(address(tokenMessenger), amount);

        _cctpSend(sender, dstChainId, amount, recipient);
    }

    function estimateFee(
        address sender,
        uint256 dstChainId,
        address recipient,
        address asset,
        bytes calldata message,
        uint256 amount,
        bytes calldata params
    )
        external
        view
        returns (uint256)
    {
        return 0;
    }

    /**
     * @notice Set the domains for the supported chain ids
     * @dev The domain is a Circle-issued identifier for a blockchain where CCTP contracts are deployed
     * @param _chainIds The list of chain ids
     * @param _domains The list of domains
     */
    function setChainIdsToDomains(uint256[] memory _chainIds, uint32[] memory _domains) external onlyOwner {
        _setChainIdsToDomains(_chainIds, _domains);
    }

    /**
     * @notice Set the mint recipients for the supported chain ids
     * @param _domains The list of domains
     * @param _recipients The list of recipients
     */
    function setMintRecipients(uint32[] memory _domains, address[] memory _recipients) external onlyOwner {
        _setMintRecipients(_domains, _recipients);
    }

    /* ----------------------------- Internal functions -------------------------------- */
    /**
     * @notice Set the domains for the supported chain ids
     * @param _chainIds The list of chain ids
     * @param _domains The list of domains
     */
    function _setChainIdsToDomains(uint256[] memory _chainIds, uint32[] memory _domains) internal {
        if (_chainIds.length == 0 || _domains.length == 0) {
            revert InvalidLength();
        }

        if (_chainIds.length != _domains.length) {
            revert MismatchedLength();
        }

        for (uint256 i; i < _chainIds.length; i++) {
            domains[_chainIds[i]] = _domains[i];
        }
    }

    /**
     * @notice Set the mint recipients for the supported chain ids
     * @param _domains The list of domains
     * @param _recipients The list of recipients
     */
    function _setMintRecipients(uint32[] memory _domains, address[] memory _recipients) internal {
        if (_domains.length == 0 || _recipients.length == 0) {
            revert InvalidLength();
        }

        if (_domains.length != _recipients.length) {
            revert MismatchedLength();
        }

        for (uint256 i; i < _domains.length; i++) {
            mintRecipients[_domains[i]] = _recipients[i];
        }
    }

    /**
     * @notice Send message via CCTP
     * @dev Revert if the network is not supported
     * @param sender The sender address
     * @param dstChainId The destination chain id
     * @param finalRecipient The recipient address
     */
    function _cctpSend(address sender, uint256 dstChainId, uint256 amount, address finalRecipient) internal {
        uint32 domain = domains[dstChainId];
        _depositForBurn(amount, domain);
        /// @dev The final recipient is the address that will receive the utility of the same value of the token
        /// @dev But the token will be minted to CCTPReceiver contract on the destination chain first
        /// @dev Then the final recipient will receive the utility of the token from CCTPReceiver contract
        emit CCTPSend(sender, dstChainId, finalRecipient);
    }

    /**
     * @notice Deposit for burn
     * @dev Revert if the network is not supported
     * @param _amount The amount of the token
     * @param _dstDomain The destination domain
     */
    function _depositForBurn(uint256 _amount, uint32 _dstDomain) internal {
        /// @dev The recipient is the address that will receive the minted token on the destination chain
        /// @dev The recipient is expected to be a CCTPReceiver contract
        address recipient = mintRecipients[_dstDomain];
        if (recipient == address(0)) {
            revert NotSupportedNetwork();
        }
        tokenMessenger.depositForBurn(_amount, _dstDomain, _addressToBytes32(recipient), address(token));
    }

    function _addressToBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }
}
