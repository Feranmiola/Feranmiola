//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/token/ERC20/IERC20.sol";

contract Pool{

    address immutable creator;
    address immutable stakingtoken;
    address immutable rewardtoken;

    uint immutable poolId;
    uint _Duration;

    bool whitelist;
    address[] whitelists;
    uint whitelistcount;   
    mapping(address => uint) counttoWhitelist;

    bool cancelled;
    bool finalised;

    uint immutable EndTime;

    constructor(address _creator, address _stakingtoken, address _rewardtoken, bool _whitelist, uint _duration, uint id){
        creator = _creator;
        stakingtoken = _stakingtoken;
        rewardtoken = _rewardtoken;
        whitelist = _whitelist;
        EndTime = _duration + block.timestamp;
        poolId = id;
        _Duration = _duration;

   }

   mapping( address => uint256) public tokenBalances;


    function fund(uint amount) external{
        require(msg.sender == creator, "NC");//Not creator
        require(!cancelled, "PC");
        require(EndTime > block.timestamp, "PE");//Pool ended
        
        IERC20 token = IERC20(rewardtoken);

        token.approve(address(this), amount);

        token.transferFrom(msg.sender, address(this), amount);
        
        tokenBalances[rewardtoken] += amount; 
    }

    function withdraw(uint amount) external{
        require(msg.sender == creator, "NC");
        require(EndTime > block.timestamp, "PE");//Pool ended
        require(!cancelled, "PC");//Pool cancelled

        require(tokenBalances[rewardtoken] > amount, "IB");//Insufficient balance

         IERC20 token = IERC20(rewardtoken);

        tokenBalances[rewardtoken] -= amount;

        token.transfer(msg.sender, amount);
    }

    function cancel() external{
        require(EndTime > block.timestamp, "PE");//Pool ended
        require(msg.sender == creator, "NC");

         IERC20 token = IERC20(rewardtoken);

        uint debit = tokenBalances[rewardtoken];

        delete tokenBalances[rewardtoken];

        token.transfer(creator, debit);

        cancelled = true;
    }


    function finalise() external{
        require(EndTime < block.timestamp, "PNE");//Pool not ended
        require(!cancelled, "PC");
        require(msg.sender == creator, "NC");
        require(!finalised, "AF");// Already finalised

        finalised = true;

        uint gain = tokenBalances[stakingtoken];

        IERC20 token = IERC20(stakingtoken);

        token.transfer(creator, gain);

        uint leftOvers = tokenBalances[rewardtoken];

        if(leftOvers > 0){
            IERC20 _token = IERC20(rewardtoken);

             delete tokenBalances[rewardtoken];

            _token.transfer(msg.sender, leftOvers);
        }
    }

    //Claiming

    uint claimNumber;
    uint claimTime;

    uint amountPerTime;

    function setClaimTIme(uint newClaimTime) external{
        require(EndTime > block.timestamp, "PE");//Pool ended
        require(!finalised, "AF");
        require(!cancelled, "PC");
        require(msg.sender == creator, "NC");

        uint _claimnumber = _Duration  / newClaimTime;

        require(_claimnumber > 1);

        claimTime = newClaimTime;
        claimNumber = _Duration / newClaimTime;
    }

    function setClaimAmount(uint newClaimAmount) external{
         require(EndTime > block.timestamp, "PE");//Pool ended
        require(!finalised, "AF");
        require(!cancelled, "PC");
        require(msg.sender == creator, "NC");


        require(newClaimAmount < tokenBalances[rewardtoken]);

        amountPerTime = newClaimAmount;
    }


    //WHitelists 


    function addWhitelists(address newAddress) external{
        require(EndTime > block.timestamp, "PE");//Pool ended
        require(whitelist, "WNT");//Whitelist not true
        require(!cancelled, "PC");
        require(msg.sender == creator, "NC");


        whitelistcount++;

        whitelists.push(newAddress);

        counttoWhitelist[newAddress] = whitelistcount;

    }

    function removeWhitelist(address oldAddress) external {
        require(EndTime > block.timestamp, "PE");//Pool ended
        require(whitelist, "WNT");//Whitelist not true
        require(!cancelled, "PC");
        require(msg.sender == creator, "NC");

        uint index = counttoWhitelist[oldAddress];

        whitelists[index] = whitelists[whitelists.length - 1];

        whitelists.pop();

        delete counttoWhitelist[oldAddress];
    }

    function offWhitelist() external {
        require(EndTime > block.timestamp, "PE");//Pool ended
        require(whitelist, "WNT");//Whitelist not true
        require(!cancelled, "PC");
        require(msg.sender == creator, "NC");

        whitelist = false;
        delete whitelists;

        delete whitelistcount;

    }



    //User end

    mapping(address => uint)public stakingBalances;
    mapping(address => uint) public rewardsBalances;
    mapping(address => uint) public userClaimNumber;
    mapping(address => uint) public userUpdatedTime;
    mapping(address => bool) public userFinalised;


    function stake(uint amount) external {
        require(msg.sender != address(0), "AZ");//Address zero
        require(EndTime > block.timestamp, "PE");//Pool ended
        require(!finalised, "PE");//Pool ended 
        require(!cancelled, "PC");//Pool cancelled

        IERC20 token = IERC20(stakingtoken);

        token.approve(address(this), amount);

        token.transferFrom(msg.sender, address(this), amount);

        stakingBalances[msg.sender] += amount;

    userUpdatedTime[msg.sender] = block.timestamp;

    }


    function unstake(uint amount) external{
        require(msg.sender != address(0), "AZ");//Address zero
        require(EndTime > block.timestamp, "PE");//Pool  ended
        require(!finalised, "PE");//Pool ended 
        require(!cancelled, "PC");//Pool cancelled
        require(amount < stakingBalances[msg.sender], "IB");//Insufficient Balance 

        uint newBal = stakingBalances[msg.sender] -= amount;
        require(newBal > 0, "CEB");//Cannot empty balance

        stakingBalances[msg.sender] -= amount;

        IERC20 token = IERC20(stakingtoken);

        token.transfer(msg.sender, amount);

   }

   function cancelStaking() external{
        require(msg.sender != address(0), "AZ");//Address zero
        require(EndTime > block.timestamp, "PE");//Pool ended
        require(!finalised, "PE");//Pool ended 
        require(!cancelled, "PC");//Pool cancelled
        require(stakingBalances[msg.sender] > 0, "YDNS"); //You did nt stake

        uint debit = stakingBalances[msg.sender];

        delete stakingBalances[msg.sender];

        IERC20 token = IERC20(stakingtoken);

        token.transfer(msg.sender, debit);
   }

   function claimRewards() external{
       require(userUpdatedTime[msg.sender] + claimTime < block.timestamp, "TNS");//Time not reached
        require(msg.sender != address(0), "AZ");//Address zero
        require(EndTime > block.timestamp, "PE");//Pool ended
        require(!finalised, "PE");//Pool ended 
        require(!cancelled, "PC");//Pool cancelled
        require(!userFinalised[msg.sender], "AF");
        require(userClaimNumber[msg.sender] < claimNumber);
       
         IERC20 token = IERC20(stakingtoken);

        uint256 claimingPercent = stakingBalances[msg.sender]  * 10000/token.balanceOf(address(this));

        uint claimAMount = claimingPercent * amountPerTime;

        rewardsBalances[msg.sender] += claimAMount;
        userClaimNumber[msg.sender]++;
        userUpdatedTime[msg.sender] = block.timestamp;

   }

   function EndStaking() external {
        require(EndTime < block.timestamp, "PE");//Pool not ended
        require(!cancelled, "PC");
        require(!userFinalised[msg.sender], "AF");//A;ready finalised
        require(userClaimNumber[msg.sender] > 0, "NCN");//No claim number
        //require(finalised, "NF");//Not finaloised
        require(rewardsBalances[msg.sender] > 0, "NB");// No balance

        IERC20 token = IERC20(rewardtoken);

        uint debit = rewardsBalances[msg.sender];
        
        delete rewardsBalances[msg.sender];
        delete userClaimNumber[msg.sender];
        delete userUpdatedTime[msg.sender];

        token.transfer(msg.sender, debit);

        delete stakingBalances[msg.sender];

        userFinalised[msg.sender] = true;


   }

   

}
