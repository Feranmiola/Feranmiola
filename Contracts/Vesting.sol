// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract Vest {

    address public immutable admin;
    
    struct VestingPriod{
        uint percent;
        uint startTime;
        uint vestingCount;
       uint MaxClaim;   
    }
    
    IERC20 token;

    constructor(address _token) {
        token = IERC20(_token);

        admin = payable(msg.sender);
    }
    uint public maxPercent;
    bool Vesting;
    uint VestingCount;
    uint unit;

    VestingPriod _vestingPeriod;

    mapping(uint => VestingPriod ) public PeriodtoPercent;
    mapping(address => uint) public TotalBalance;
    mapping(address => uint) private claimCount;
    mapping(address => uint) private claimedAmount;
    mapping(address => uint) private claimmable;
    mapping(address => uint) public TokenBalance;

    modifier onlyAdmin{
        require(msg.sender == admin, "Not admin");
        _;
    }


    function _vesting() external{
       
        Vesting = true; 
    }
    

    function setVesting(uint StartTime, uint StartPercentage) external {
        
        require(Vesting, "VF");//Vesting was not set to true
           VestingCount++;
           maxPercent += StartPercentage;
        if(maxPercent > 100){
            maxPercent -=StartPercentage;
            revert ();
        }
        else {
        PeriodtoPercent[VestingCount] = VestingPriod({
            percent : StartPercentage,
            startTime : StartTime,
            vestingCount : VestingCount,
              MaxClaim : maxPercent
        });

        }
      

    }

    function setUnit(uint newUnit) external onlyAdmin{
        unit = newUnit;
    }

    function claim() external {
        require(Vesting);
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

        TotalBalance[msg.sender] -= _amount;
        claimedAmount[msg.sender] += claimmable[msg.sender]; 
  
        delete claimmable[msg.sender];

        token.transfer(msg.sender, _amount);


     
    }

    receive() external payable{
        buy();
    }

    function buy() public payable{
        uint amount = unit * msg.value;
        TokenBalance[msg.sender] +=amount;
        TotalBalance[msg.sender] +=amount;
    }
    function getBalance() external view returns(uint){
        return token.balanceOf(address(this));
    }
}
