// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


interface iStakingContracts{
    function setDataStorage(address newStorage) external;
    function dataStorageCaller_pauseContract() external;
    function dataStorageCaller_changeTokenA(address _newTokenA) external;
    function dataStorageCaller_changeTokenB(address _newTokenB) external;
}
contract database is Initializable{
    
    address public admin;
    address public tokenA;
    address public tokenB;

    function initialize(address _tokenA, address _tokenB) external initializer{
        admin = payable(msg.sender);

        tokenA = _tokenA;
        tokenB = _tokenB;

    }








  ////////////////////////////////////////////////////
  ////////////////////////////////////////////////////
  ////////////////////////////////////////////////////
  ///////////////GENERAL FUNCTIONS////////////////////
  ////////////////////////////////////////////////////
  ////////////////////////////////////////////////////



    function _transfer(address _token, address reciever, uint amount) external returns(bool){
  
        if(msg.sender == p2pCaller || msg.sender == poolCaller || authorizedAddress[msg.sender] || msg.sender == admin)  {
            
            IERC20Upgradeable token = IERC20Upgradeable(_token);

            token.transfer(reciever, amount);

            return true;
        }else{
         revert("Unauthorised address");   
        }
       
   }

   
    function normalTransfer(address _token, address reciever, uint amount) internal returns(bool){
        
        IERC20Upgradeable token = IERC20Upgradeable(_token);

        token.transfer(reciever, amount);  
        
        return true;
   }



  ////////////////////////////////////////////////////
  ////////////////////////////////////////////////////
  ////////////////////////////////////////////////////
  /////////////////LOGIC FUNCTIONS////////////////////
  ////////////////////////////////////////////////////
  ////////////////////////////////////////////////////




    mapping(address => mapping(string => mapping(uint => uint))) public BetidToStake;
    mapping(address => mapping(string => mapping(uint => address))) public TokenToStake;
    mapping(string => uint) public BetIdtoTotal;
    mapping(string => uint) public BetCount;
    mapping(address => mapping(string => mapping(uint => bool))) public BetidToClaimed;
    mapping(address => mapping(string => mapping(uint => bool))) public Staked;
    mapping(string => bool) public FullyClaimed;
    mapping(string => string) public Game;

    mapping(string => address) public firstAddress;
    mapping(string => bool) public BetidStored;
    mapping(uint => string) public IndextoBetid;
    uint public BetidNumber;

    string[] public BetidArray;


 
    function SaveStakeData(address _token, address staker, string calldata  betid,uint transactionID, uint stakeAmount, string calldata game) external {
        if(msg.sender == p2pCaller || msg.sender == poolCaller){
            if(!BetidStored[betid]){
                BetidStored[betid] = true;
                BetidNumber++;   
                BetidArray.push(betid);
                IndextoBetid[BetidNumber];

            }

            BetidToStake[staker][betid][transactionID] += stakeAmount;
            BetIdtoTotal[betid] += stakeAmount;
            BetCount[betid] +=1;
            TokenToStake[staker][betid][transactionID] = _token;
            Staked[staker][betid][transactionID] = true;


            Game[betid] = game;
        }
        else{
            revert("Unauthorized Caller");
        } 

    }



    function setFirstAddress(address _token, string calldata betid) external {
        firstAddress[betid] =_token;
    }


function SaveFinalise(string calldata betid, uint transactionID, address reciever, uint amount, uint newamount, uint fee, bool last) external {
        if(msg.sender == p2pCaller || msg.sender == poolCaller){
        
            BetidToClaimed[reciever][betid][transactionID] = true;        
            delete BetidToStake[reciever][betid][transactionID];

            BetIdtoTotal[betid] -= amount;

            adminTotaFee[TokenToStake[reciever][betid][transactionID]] += fee;

            LastClaim(TokenToStake[reciever][betid][transactionID], betid, last, BetIdtoTotal[betid]);
            
            IERC20Upgradeable token = IERC20Upgradeable(TokenToStake[reciever][betid][transactionID]);
            token.transfer(admin, fee);
              
        if (bonus == true && TokenToStake[reciever][betid][transactionID] == bonusAddress){
          Bonus(newamount, reciever);
        }

        }
        else{
            revert("Unauthorized Caller");
        }

   }

    function Bonus(uint amount, address reciever) internal{

         amount = amount * bonusPercent/ 10000;
         if(amount > maxBonusAmount){

             amount = maxBonusAmount;
         }

        normalTransfer(bonusAddress, reciever, amount);

    }

   
  function LastClaim(address _token, string calldata betid, bool last, uint residual) internal{
        FullyClaimed[betid] = last;

        if(FullyClaimed[betid]){
            totalResiduals[_token] += residual;
        }
    }

    
        
    function _GetStaked(string calldata  betid, uint transactionID, address staker) external  view returns(bool){
        if(msg.sender == p2pCaller || msg.sender == poolCaller){
        
            return Staked[staker][betid][transactionID];
        }
        else{
            revert("Unauthorized Caller");
        }
        
    }

    function _GetFinalised(string calldata  betid, uint transactionID, address reciever) external  view returns(bool){
        if(msg.sender == p2pCaller || msg.sender == poolCaller){
            return BetidToClaimed[reciever][betid][transactionID];
        }
        else{
            revert("Unauthorized Caller");
        }
    }

    function GetStake(string calldata betid, uint transactionID, address staker) external  view returns(uint){
        if(msg.sender == p2pCaller || msg.sender == poolCaller){
            return BetidToStake[staker][betid][transactionID];
        }
        else{
            revert("Unauthorized Caller");
        }
        
    }
    function GetTotalStake(string calldata betid) external view returns(uint){
        if(msg.sender == p2pCaller || msg.sender == poolCaller){
             return BetIdtoTotal[betid];
        }
        else{
            revert("Unauthorized Caller");
        }
        
    } 
    function _GetTokenToStake(string calldata betid, uint transactionID, address reciever) external  view returns(address){
         if(msg.sender == p2pCaller || msg.sender == poolCaller){

            return TokenToStake[reciever][betid][transactionID];
        }
        else{
            revert("Unauthorized Caller");
        }
        
    }
    function getBetCount(string calldata betid) external view returns(uint){
           if(msg.sender == p2pCaller || msg.sender == poolCaller){

            return BetCount[betid];
        }
        else{
            revert("Unauthorized Caller");
        }
    }
    function getFirstAddress(string calldata betid) external view returns (address){
         if(msg.sender == p2pCaller || msg.sender == poolCaller){

            return firstAddress[betid];
        }
        else{
            revert("Unauthorized Caller");
        }
    }
    function getbetidStored(string calldata betid) external view returns(bool){
         if(msg.sender == p2pCaller || msg.sender == poolCaller){

            return BetidStored[betid];
        }
        else{
            revert("Unauthorized Caller");
        }
    }





  ////////////////////////////////////////////////////
  ////////////////////////////////////////////////////
  ////////////////////////////////////////////////////
  ///////////////ADMIN FUNCTIONS//////////////////////
  ////////////////////////////////////////////////////
  ////////////////////////////////////////////////////



    
    mapping (address => uint) public adminTotaFee;
    mapping (address => uint) public totalResiduals;
    mapping(address => bool) public authorizedAddress;

    bool public bonus;
    uint public bonusPercent;
    uint public maxBonusAmount;
    address public bonusAddress;
    address public p2pCaller;
    address public poolCaller;

    function getTotalResidue(address _token) external view returns(uint){
          require(msg.sender == admin, "Not Admin");
        return totalResiduals[_token];
    }


        
    
    function adminResidualWithdraw(address _token) external{
          require(msg.sender == admin, "Not Admin");
          require(totalResiduals[_token] > 0, "No Residuals Available");
        
        IERC20Upgradeable token = IERC20Upgradeable(_token);

          uint residual = totalResiduals[_token];

          delete totalResiduals[_token];

          token.transfer(admin, residual);
    }

    function setBonus() external{
        require(msg.sender == admin, "Not Admin");
        if(bonus){
            bonus = false;
        }else{
            bonus = true;
        }
    }

    function bonusDetails(address _bonusAddress, uint _max, uint percent) external{
        require(msg.sender == admin, "Not Admin");
        require(bonus, "Bonus not set");

        maxBonusAmount = _max;
        bonusPercent = percent;
        bonusAddress = _bonusAddress;

    }

    function setP2Pcaller(address caller) external{
     require(msg.sender == admin, "Not Admin");

     p2pCaller = caller;

    }


    function setPoolCaller(address _caller) external{
        require(msg.sender == admin, "Not Admin");
        poolCaller = _caller;

    }
    
    function _Migrate(address migrator) external{
        require(msg.sender == admin, "Not Admin");

        IERC20Upgradeable token = IERC20Upgradeable(tokenA);

        
        normalTransfer(tokenA, migrator, token.balanceOf(address(this)));


        IERC20Upgradeable token2 = IERC20Upgradeable(tokenB);

        normalTransfer(tokenB, migrator, token2.balanceOf(address(this)));


    }

    function changeAdmin(address _newAdmin) external{
        require(msg.sender == admin, "Not Admin");
        
        admin = _newAdmin;
    }

    function pauseP2P() external {
        require(msg.sender == admin, "Not Admin");

        iStakingContracts(p2pCaller).dataStorageCaller_pauseContract();

    }
    function pausePool() external{
         require(msg.sender == admin, "Not Admin");

        iStakingContracts(poolCaller).dataStorageCaller_pauseContract();   
    }

    function changeTokenA(address _newToken) external{
         require(msg.sender == admin, "Not Admin");
        
        tokenA = _newToken;
        iStakingContracts(p2pCaller).dataStorageCaller_changeTokenA(_newToken);
        iStakingContracts(poolCaller).dataStorageCaller_changeTokenA(_newToken);
    }

    
    function changeTokenB(address _newToken) external{
         require(msg.sender == admin, "Not Admin");
        
        tokenB = _newToken;
        iStakingContracts(p2pCaller).dataStorageCaller_changeTokenB(_newToken);
        iStakingContracts(poolCaller).dataStorageCaller_changeTokenB(_newToken);
    }

    function allowAccess(address newMember) external{
        require(msg.sender == admin, "Not Admin");

        authorizedAddress[newMember] = true;
    }

    function revokeAccress(address member) external{
        require(msg.sender == admin, "Not Admin");

        authorizedAddress[member] = false;
    }

    function getAdmin() external view returns(address){
        return admin;
    }
    function getTokenA() external view returns(address){
        return tokenA;
    }
    function getTokenB() external view returns(address){
        return tokenB;
    }


}