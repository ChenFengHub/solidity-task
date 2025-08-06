// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTBid is ERC721 { 

    uint256 private _tokenId = 0;
    mapping(uint256 tokenId => string tokenURI) private _tokenURIs;

    constructor() ERC721("MyNFT", "MNFT") {}

    // 铸造NFT。转移函数：safeTransferFrom是默认自带实现满足要求，无需进行实现
    function mintNFT(address recipient, string memory tokenURI) public returns (uint256) {
        _tokenId++;
        _mint(recipient, _tokenId);
        _setTokenURI(_tokenId, tokenURI);
        return _tokenId;
    }
    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        return  _tokenURIs[tokenId];
    }
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        require(_ownerOf(tokenId) != address(0), "ERC721: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

}