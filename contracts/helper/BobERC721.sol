pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BobERC721 is ERC721 {
    constructor() ERC721("Bob", "BOB") {
        _mint(msg.sender, 1);
        _mint(msg.sender, 2);
    }

    function transfer(address to, uint256 tokenId) public {
        _transfer(msg.sender, to, tokenId);
    }
}
