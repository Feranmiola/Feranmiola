// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TokenMaker.sol";

contract Mint{

    struct TokenDetails{
        address creator;
        address tokenaddress;
        string name;
        string symbols;
        uint8 decimals;
        uint256 __totalSupply;
    }


    uint256 tokenCount;

    TokenDetails[] tokenDetailsArray;
    mapping(address => TokenDetails[]) personalTokenDetails;
    event TokenCreated(address indexed owner, address tokenaddress, string name, string symbols, uint8 decimals, uint totalSupply);

    function createNewToken(string calldata tokenName, string calldata tokenSymbols, uint8 decimals__, uint totalSupply) external returns(address){
        Token newToken = new Token(msg.sender, tokenName, tokenSymbols, decimals__, totalSupply);


        tokenDetailsArray.push( TokenDetails({
                                creator : msg.sender,
                                tokenaddress : address(newToken),
                                name : newToken.name(),
                                symbols : newToken.symbol(),
                                decimals : newToken.decimals(),
                                __totalSupply : newToken.totalSupply()
                                }));

        personalTokenDetails[msg.sender].push( TokenDetails({
                                creator : msg.sender,
                                tokenaddress : address(newToken),
                                name : newToken.name(),
                                symbols : newToken.symbol(),
                                decimals : newToken.decimals(),
                                __totalSupply : newToken.totalSupply()
                                }));


        emit TokenCreated(msg.sender, address(newToken), tokenName, tokenSymbols,  decimals__,  totalSupply);

        tokenCount++;
        
        return(address(newToken));

    }

    function getAllTokensCreated() external view returns(TokenDetails[] memory){
        return tokenDetailsArray;
    }

    function getAllTokensCreatedForUser(address user) external view returns(TokenDetails[] memory){
        return personalTokenDetails[user];
    }

    function getTotalNumberOfTokensCreated() external view returns(uint){
        return tokenCount;
    }
}