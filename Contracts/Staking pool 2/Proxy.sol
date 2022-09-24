//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Pool.sol";

contract proxy{

    address immutable admin;

    constructor() {
        admin = payable(msg.sender);
    }

    uint256 creationFee;

    mapping(uint => address) counttoAddress;

    uint256 poolcount;

    function setcreationFee(uint newcreationfee) external{
        require(msg.sender == admin, "Na");

        creationFee = newcreationfee;
    }

    function createNewPool(address stakingtoken, address rewardstoken, bool whitelist, uint duration) external payable {
        require(creationFee > 0, "CFNS");// Creation fee not set
        require(msg.value >= creationFee, "CFNC");//Creation fee not complete

        poolcount++;

        Pool pool = new Pool(msg.sender, stakingtoken, rewardstoken, whitelist, duration, poolcount);

        counttoAddress[poolcount] = address(pool);
    }

    
}
