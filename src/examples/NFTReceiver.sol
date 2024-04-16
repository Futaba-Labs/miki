// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { IMikiAppReceiver } from "../interfaces/IMikiAppReceiver.sol";
import { ERC721URIStorage } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTReceiver is IMikiAppReceiver, ERC721URIStorage {
    uint256 private _nextTokenId;
    string private _tokenURI;

    address public mikiReceiver;

    event MikiNFTMinted(address to, uint256 tokenId);

    error NotMikiReceiver();

    constructor(string memory _uri, address _mikiReceiver) ERC721("Miki Sample NFT", "MIKI") {
        _tokenURI = _uri;
        mikiReceiver = _mikiReceiver;
    }

    modifier onlyMikiReceiver() {
        if (msg.sender != mikiReceiver) revert NotMikiReceiver();
        _;
    }

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

    function mikiReceiveMsg(uint256, address, bytes calldata message) external payable onlyMikiReceiver {
        address to = abi.decode(message, (address));
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        emit MikiNFTMinted(to, tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenURI;
    }

    fallback() external payable { }

    receive() external payable { }
}
