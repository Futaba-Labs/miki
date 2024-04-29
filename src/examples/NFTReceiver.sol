// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { IMikiAppReceiver } from "../interfaces/IMikiAppReceiver.sol";
import { ERC721URIStorage } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title NFTReceiver
 * @notice This contract is used to mint NFTs from Miki
 */
contract NFTReceiver is IMikiAppReceiver, ERC721URIStorage {
    /* ----------------------------- Storage -------------------------------- */
    /// @notice The next token id
    uint256 private _nextTokenId;

    /// @notice The token URI
    string private _tokenURI;

    /// @notice The MikiReceiver address
    address public mikiReceiver;

    /* ----------------------------- Events -------------------------------- */
    /// @notice This event is emitted when a token is minted
    event MikiNFTMinted(address to, uint256 tokenId);

    /* ----------------------------- Errors -------------------------------- */
    /// @notice This error is emitted when the sender is not the MikiReceiver
    error NotMikiReceiver();

    /* ----------------------------- Constructor ----------------------------- */
    /**
     * @notice This constructor is used to initialize the contract
     * @param _uri The token URI
     * @param _mikiReceiver The MikiReceiver address
     */
    constructor(string memory _uri, address _mikiReceiver) ERC721("Miki Sample NFT", "MIKI") {
        _tokenURI = _uri;
        mikiReceiver = _mikiReceiver;
    }

    /* ----------------------------- Modifiers ----------------------------- */
    modifier onlyMikiReceiver() {
        if (msg.sender != mikiReceiver) revert NotMikiReceiver();
        _;
    }

    /**
     * @notice This function is used to receive a message and token from Miki and mint NFT
     * @param token The token address
     * @param amount The amount of the token
     * @param message The message
     */
    function mikiReceive(
        uint256,
        address,
        address token,
        uint256 amount,
        bytes calldata message
    )
        external
        payable
        onlyMikiReceiver
    {
        address to = abi.decode(message, (address));
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        emit MikiNFTMinted(to, tokenId);
    }

    /**
     * @notice This function is used to receive a message from Miki and mint NFT
     * @param message The message
     */
    function mikiReceiveMsg(uint256, address, bytes calldata message) external payable onlyMikiReceiver {
        address to = abi.decode(message, (address));
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        emit MikiNFTMinted(to, tokenId);
    }

    /**
     * @notice This function is used to get the base URI
     * @return The base URI
     */
    function _baseURI() internal view override returns (string memory) {
        return _tokenURI;
    }

    fallback() external payable { }

    receive() external payable { }
}
