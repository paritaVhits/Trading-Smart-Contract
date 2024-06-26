// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";

contract NFT is ERC721URIStorage{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address contractAddress;

    constructor() ERC721("NFT","VHNFT") {
        contractAddress = address(this);
    }

    function createToken(string memory tokenURI)public returns(uint) {
        _tokenIds.increment();
        uint newItemId = _tokenIds.current();
        _mint(msg.sender,newItemId);
        _setTokenURI(newItemId, tokenURI);
        setApprovalForAll(contractAddress, true);
        return newItemId;
    }

    function getCurrentTokenId() public view returns (uint) {
        return _tokenIds.current();
    }
}