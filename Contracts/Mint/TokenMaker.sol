// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Token is ERC20, Ownable {
    constructor(address Owner, string memory tokenName, string memory tokenSymbols, uint8 decimals__, uint totalSupply) ERC20(tokenName, tokenSymbols, decimals__) {
        transferOwnership(Owner);
        _mint(Owner, totalSupply * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }



}