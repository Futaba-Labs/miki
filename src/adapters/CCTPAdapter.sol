// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ICCTPAdapter } from "../interfaces/ICCTPAdapter.sol";
import { ITokenMessenger } from "../interfaces/ITokenMessenger.sol";

/**
 * @title CCTPAdapter
 * @notice CCTPAdapter is an adapter contract for using CCTP
 */
contract CCTPAdapter is ICCTPAdapter, Ownable {
    /* ----------------------------- Storage -------------------------------- */
    ITokenMessenger public immutable tokenMessenger;

    /// @dev The token will be burned on the source chain and minted on the destination chain, basically $USDC or $EURC
    IERC20 public immutable token;

    /// @notice Mapping: ChainId => MintRecipient
    /// @dev The mint recipient is the address that will receive the minted token on the destination chain
    mapping(uint256 chainId => address recipient) public mintRecipients;

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
    }

    /**
     * @notice Send message via CCTP
     * @dev Revert if the network is not supported
     * @param sender The sender address
     * @param dstChainId The destination chain id
     * @param recipient The recipient address
     */
    function cctpSend(address sender, uint256 dstChainId, address recipient) external payable {
        uint32 domain = domains[dstChainId];
        _depositForBurn(sender, msg.value, domain);
        emit CCTPSend(sender, dstChainId, recipient);
    }

    /**
     * @notice Set the domains for the supported chain ids
     * @dev The domain is a Circle-issued identifier for a blockchain where CCTP contracts are deployed
     * @param _chainIds The list of chain ids
     * @param _domains The list of domains
     */
    function setChainIdsToDomains(uint256[] calldata _chainIds, uint32[] calldata _domains) external onlyOwner {
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

    /* ----------------------------- Internal functions -------------------------------- */
    function _depositForBurn(address sender, uint256 _value, uint32 _dstDomain) internal {
        address recipient = mintRecipients[_dstDomain];
        if (recipient == address(0)) {
            revert NotSupportedNetwork();
        }
        tokenMessenger.depositForBurn(_value, _dstDomain, _addressToBytes32(recipient), address(token));

        emit DepositForBurn(sender, _dstDomain);
    }

    function _addressToBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }
}
