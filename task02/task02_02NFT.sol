// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";


contract MyNFT is ERC721 {

    mapping(uint256 tokenId => string tokenURI) tokenURIs; 
       
    constructor() ERC721("MyNFT", "MySymbol") {}

    // 铸造NFT
    function mintNFT(address recipient, uint256 tokenId, string memory tokenURI) external {
        _mint(recipient, tokenId);  // _mint()不能保证令牌先铸造完成，使用安全方法_safeMint来保证
    //    _safeMint(recipient, tokenId);
       setTokenURI(tokenId, tokenURI);
    }

    // 根据tokenId获取uri
    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        return tokenURIs[tokenId];
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
        require(_exists(tokenId), "ERC721: URI set of nonexistent token");
        tokenURIs[tokenId] = _tokenURI;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return bytes(tokenURIs[tokenId]).length > 0;
    }

}