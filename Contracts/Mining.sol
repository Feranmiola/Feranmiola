// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MiningContract{
    
    address immutable admin;

    IERC20 token;

    uint stage1Fee = 10000000000000000;
    uint stage2Fee = 100000000000000000;
    uint stage3Fee = 1000000000000000000;

    enum Stages{
        Level1,
        Level2,
        Level3
    }
    Stages stages;


    mapping(address => uint) private maximumcCount;
    mapping(IERC20 => mapping(address => uint)) private paidAmount;
    mapping(Stages => mapping(address => uint)) private paymentPlan;
    mapping(address => Stages) public checkStage;
    mapping(address => uint) public EthPaid;
    mapping(IERC20 => uint) private totalPaid;
    mapping(IERC20 => uint) private totalMinted;
    mapping(address => uint) public balances;

    event Withdrawn(address indexed reciever, uint amount);
    event Mined(address indexed miner, uint amount);
    event Payment(address indexed payee, uint amount);
    event PulledBack(address administrator, uint amount);
    event AdminWithdraw(address administrator, uint amount);
    event Paidplan(Stages indexed stages, address miner, uint amount);


    constructor(address _token){
        admin = payable(msg.sender);
        token = IERC20(_token);
    }


    receive() external payable {
        conditionChecker(msg.sender, msg.value);   

        emit Payment(msg.sender, msg.value);
    }

    modifier onlyAdmin{
        require(msg.sender == admin);
        _;
    }

    modifier countReached(){
        require(maximumcCount[msg.sender] >=0, "Maximum minings reached");
        _;
    }

    function tokenGetBalance() external onlyAdmin view returns(uint){
        return token.balanceOf(address(this));
    }

   function tokenGetMinted() external onlyAdmin view returns(uint){
        return totalMinted[token];
    }

    function tokenGetPaid() external onlyAdmin view returns(uint){
        return totalPaid[token];
    }


    function Mine() external countReached(){

        balances[msg.sender] += paymentPlan[stages][msg.sender];
        maximumcCount[msg.sender] --;

        emit Mined(msg.sender, paymentPlan[stages][msg.sender]);
    }

    function Withdraw(address reciever, uint amount) external{

        require(reciever == msg.sender);
        require(amount <= balances[reciever], "Insufficient Balance");
        require(amount < token.balanceOf(address(this)), "Not enough in the pool, Wait for admin refund");

        balances[reciever] -= amount;

        SafeERC20.safeTransfer(token, reciever, amount);

        totalPaid[token] += amount;
        totalMinted[token] += amount;

        emit Withdrawn(reciever, amount);
    }

    function adminWithdraw() external onlyAdmin payable{

        require(address(this).balance >0, "Balance too low");

        payable(admin).transfer(address(this).balance);

        emit AdminWithdraw(admin, address(this).balance);
    }

    function PullBack(uint amount) external onlyAdmin{

        require(amount < token.balanceOf(address(this)), "You are pulling too much");
        SafeERC20.safeTransfer(token, admin, amount);
          
          emit PulledBack(admin, amount);
    }

    function levelSetter(address miner, uint amount) private{
        if(amount == 10000000000000000){
            stages = Stages.Level1;

            paymentPlan[stages][miner] = 20000000000000000000;
            checkStage[miner] == stages;

            emit Paidplan(stages, miner, amount);
        }
        else {
            if(amount == 100000000000000000){
                stages = Stages.Level2;

                 paymentPlan[stages][miner] = 200000000000000000000;
                 checkStage[miner] == stages;

                 emit Paidplan(stages, miner, amount);
            }
            else {
                if(amount == 1000000000000000000)
                {
                    stages = Stages.Level3;

                     paymentPlan[stages][miner] = 2000000000000000000000;
                     checkStage[miner] == stages;

                     emit Paidplan(stages, miner, amount);
                }
            }
        }
    }

    function conditionChecker(address miner, uint amount) private {
       if(amount == 10000000000000000){
        
         EthPaid[miner] = amount; 
        levelSetter(miner, amount);
        maximumcCount[miner] += 10;

       } else {
           if(amount == 100000000000000000){
                EthPaid[miner] = amount; 
                levelSetter(miner, amount);
                maximumcCount[miner] += 15;
           }
           else {
               if(amount == 1000000000000000000){
                EthPaid[miner] = amount; 
                levelSetter(miner, amount);
                maximumcCount[miner] += 25;
               }
               else 
                revert("You paid too much or too little, send 0.01 eth or 0.1 eth or 1 eth");
           }
       }
    }

}
