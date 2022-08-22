// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC.sol";

contract Presale{
    address public immutable admin;
    IERC20 token;

    event AdminWithdrawal(uint bnbAmount, uint tokenAmount);

    //Presale
    uint256 public bnbunit;
    uint256 public hardCap;
    uint256 public raisedBNB;

    mapping(address => uint) public spentBNB;
    mapping(address => uint) public boughtTokens;

    bool public presaleStart;
    bool public presaleEnd;

    event presaleStarted(uint starttime, uint _hardcap, uint tokenAmount);
    event Bought(address indexed buyer, uint tokenAmouunt, uint bnbAmount);
    event Withdraw(address indexed withdrawer, uint tokenAmount, uint bnbAmount);
    event PresaleEnded(uint endTime, uint _raisedBNB, uint tokenLeft);

    //Vesting
     
    struct VestingPriod{
        uint percent;
        uint startTime;
        uint vestingCount;
       uint MaxClaim;   
    }
    
    uint maxPercent;
    bool Vesting;
    uint VestingCount;

    VestingPriod _vestingPeriod;

    mapping(uint => VestingPriod ) public PeriodtoPercent;
    mapping(address => uint) private TotalBalance;
    mapping(address => uint) private claimCount;
    mapping(address => uint) private claimedAmount;
    mapping(address => uint) private claimmable;

    event VestingSet(uint startTime, uint Percent, uint TotalPercent);
    event Claimed(address indexed claimer, uint Precent, uint tokenAmount);




    constructor(address _token, uint buyUnit, uint hardcap) {
        admin = payable(msg.sender);
        token = IERC20(_token);
        hardCap = hardcap;
        bnbunit = buyUnit;       
    } 

    //Presale
    function startPresale() external {
        require(msg.sender == admin);
        uint tokenBalance = hardCap * bnbunit;

        require(tokenBalance <= token.balanceOf(address(this)));

        presaleStart = true; 

       emit  presaleStarted(block.timestamp, hardCap, token.balanceOf(address(this)));
    }

    receive() external payable{
        buy();
    }

    function buy() public payable{
        require(presaleStart, "PO"); //Presale Off
        require(raisedBNB + msg.value <= hardCap, "TM");//Too much, gone over hard cap

        uint256 tokenAmount = msg.value * bnbunit;

        spentBNB[msg.sender]+=msg.value;
        boughtTokens[msg.sender]+=tokenAmount;
        TotalBalance[msg.sender] +=tokenAmount;
        raisedBNB+=msg.value;

        emit Bought(msg.sender, msg.value, tokenAmount);


    }
    function getBalance() external view returns(uint){
        return token.balanceOf(address(this));
    }

    function emergencyWithdrawal(uint amount) external{
        require(presaleStart, "PO");
        require(spentBNB[msg.sender] >= amount);

        uint tokenDebit = amount * bnbunit;

        boughtTokens[msg.sender] -= tokenDebit;
        spentBNB[msg.sender] -= amount;

       (bool sent,) = msg.sender.call{value: amount}("");
        require(sent, "Fail");

        emit Withdraw(msg.sender, amount, tokenDebit);

    }

    function endPresale() external{
        require(msg.sender == admin, "NA");//Not admin
        require(presaleStart, "PO");//Presale Off

        presaleStart = false;
        presaleEnd = true;

        emit PresaleEnded(block.timestamp, raisedBNB, token.balanceOf(address(this)));
    }
    
    //Vesting 
 

    function setVesting(uint StartTime, uint Percentage) external {

           VestingCount++;
           maxPercent += Percentage;
        if(maxPercent > 100){
            maxPercent -=Percentage;
            revert ();
        }
        else {
            require(StartTime > PeriodtoPercent[VestingCount-1].startTime);
        PeriodtoPercent[VestingCount] = VestingPriod({
            percent : Percentage,
            startTime : StartTime,
            vestingCount : VestingCount,
              MaxClaim : maxPercent
        });

        }

        emit VestingSet(StartTime, Percentage, maxPercent);
    }

  
    function claim() external {
        require(presaleEnd, "PA");
        require(claimCount[msg.sender] <= VestingCount,"CC");//Claiming Complete
        claimCount[msg.sender] ++;

        for(uint i = claimCount[msg.sender]; i<= VestingCount; i++){
            if(PeriodtoPercent[i].startTime <= block.timestamp){
                claimmable[msg.sender] +=PeriodtoPercent[i].percent;
            }
            else 
            break;
        }
        
    
        require(claimmable[msg.sender] <= 100);
        

        uint _amount = (claimmable[msg.sender] *100) * TotalBalance[msg.sender]/10000;

        boughtTokens[msg.sender] -= _amount;
        claimedAmount[msg.sender] += claimmable[msg.sender]; 

        uint _Percent = claimmable[msg.sender];
  
        delete claimmable[msg.sender];

        token.transfer(msg.sender, _amount);

        emit Claimed(msg.sender, _Percent, _amount);

    }
    //Admin Withdrawal

    function WithdrawRemainingFunds() external{
        require(msg.sender==admin, "NA");
        uint tokenBalance = token.balanceOf(address(this));

        if(raisedBNB < hardCap || tokenBalance > 0){
            token.transfer(admin, token.balanceOf(address(this)));
        }

         (bool sent,) = admin.call{value: raisedBNB}("");
        require(sent, "Fail");

        emit AdminWithdrawal(raisedBNB, tokenBalance);
    }





    
}
