// SPDX-License-Identifier: MIT
pragma solidity ^0.8;


import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IAny2EVMMessageReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IAny2EVMMessageReceiver.sol";
import {IERC165} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/utils/introspection/IERC165.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

contract AuctionNFTReceiver is CCIPReceiver, ERC721 {
    // 存储源链NFT合约地址 → 目标链Wrapped NFT映射
    mapping(address => address) public originalToWrapped; 
    mapping(uint256 => string) public tokenUrls;
    address private immutable i_router;

    // 事件记录
    event NFTReceived(
        bytes32 messageId,
        bytes sender, 
        address nftContract,
        address owner,
        uint256 tokenId,
        string tokenURI
    );

    constructor(address router) 
        ERC721("Wrapped NFT", "WNFT")
        CCIPReceiver(router) 
    {
        i_router = router;
    }
    
    /**
     * 接收来自源链的Token
     */
    function _ccipReceive(
        Client.Any2EVMMessage memory message
    ) internal override {
        (address srcNftContract, uint256 tokenId, address owner, string memory tokenURI) = 
            abi.decode(message.data, (address, uint256, address, string));
        
        // 1. 铸造Wrapped NFT给原所有者
        _safeMint(owner, tokenId);
        // 2. 设置元数据（从源链NFT合约读取或预设URI）
        setTokenURI(tokenId, tokenURI); 
        // 3. 记录映射关系
        originalToWrapped[srcNftContract] = address(this);
        emit NFTReceived(
            message.messageId,
            message.sender,
            srcNftContract,
            owner,
            tokenId,
            getTokenURI(tokenId)
        );
    }

    function getTokenURI(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return tokenUrls[tokenId];
    }

    function setTokenURI(uint256 tokenId, string memory tokenUrl) public {
        tokenUrls[tokenId] = tokenUrl;
    }
    
    // 解决ERC165接口冲突的正确方法
    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(CCIPReceiver, ERC721)
        returns (bool)
    {
        // 直接实现两个合约需要支持的接口检查
        return interfaceId == type(IAny2EVMMessageReceiver).interfaceId || 
               interfaceId == type(IERC165).interfaceId ||
               interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Metadata).interfaceId;
    }
}