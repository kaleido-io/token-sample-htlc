pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BobERC721 is ERC721 {
    constructor() ERC721("Bob", "BOB") {}

    function transfer(address to, uint256 tokenId) public {
        _transfer(msg.sender, to, tokenId);
    }

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}
