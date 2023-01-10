// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract database is Initializable{
     address public admin;
    // IERC20 public immutable token;
    // storageP2P public storageP2p;

    function initialize() external initializer{
        admin = payable(msg.sender);
        // token = IERC20(0x11d1149202fbb7eeeA118BCEb85db1D7eAA3084A);
   

    }









  ////////////////////////////////////////////////////
  ////////////////////////////////////////////////////
  ////////////////////////////////////////////////////
  ///////////////GENERAL FUNCTIONS////////////////////
  ////////////////////////////////////////////////////
  ////////////////////////////////////////////////////


    modifier onlyCaller {
        if(msg.sender == p2pCaller){
            _;
        }else if(msg.sender == poolCaller){
            _;
        }else if(msg.sender == extraCaller){
            _;
        }else if(msg.sender == admin){
            _;
        }else if(msg.sender == migrator){
            _;
        }else{
            revert("Unauthorised address");
        }
    }


    function _transfer(address _token, address reciever, uint amount) external onlyCaller returns(bool){
  
        IERC20Upgradeable token = IERC20Upgradeable(_token);

        token.transfer(reciever, amount);

        return true;
   }

   
    function normalTransfer(address _token, address reciever, uint amount) internal returns(bool){
        
        IERC20Upgradeable token = IERC20Upgradeable(_token);

        token.transfer(reciever, amount);  
        
        return true;
   }


















  ////////////////////////////////////////////////////
  ////////////////////////////////////////////////////
  ////////////////////////////////////////////////////
  /////////////////P2P FUNCTIONS//////////////////////
  ////////////////////////////////////////////////////
  ////////////////////////////////////////////////////




    mapping(address => mapping(string => uint)) public p2pBetidToStake;
    mapping(address => mapping(string => address)) public p2pTokenToStake;
    mapping(string => uint) public P2PBetIdtoTotal;
    mapping(string => uint) public p2pBetCount;
    mapping(address => mapping(string => bool)) public p2pBetidToClaimed;
    mapping(address => mapping(string => bool)) public p2pStaked;
    mapping(string => bool) public p2pfullyClaimed;
    mapping(string => string) public p2pGame;
    mapping(string => address) public p2pfirstAddress;
    mapping(string => bool) public p2pBetidStored;
    mapping(uint => string) public p2pIndextoBetid;
    uint public p2pBetidNumber;

    string[] public p2pBetidArray;
   

    function p2pSaveStakeData(address _token, address staker, string calldata  betid, uint stakeAmount, string calldata game) external{
            
            require(msg.sender == p2pCaller, "You are not allowed to call");

            if(!p2pBetidStored[betid]){
                p2pBetidStored[betid] = true;
                p2pBetidNumber++;   
                p2pBetidArray.push(betid);
                p2pIndextoBetid[p2pBetidNumber];

            }
 
            p2pBetidToStake[staker][betid] += stakeAmount;
            P2PBetIdtoTotal[betid] += stakeAmount;
            p2pBetCount[betid] +=1;
            p2pTokenToStake[staker][betid] = _token;

            p2pStaked[msg.sender][betid] = true;
            
            p2pGame[betid] = game;

    }



    function setP2PFirstAddress(address _token, string calldata betid) external{
        require(msg.sender == p2pCaller, "You are not allowed to call");
        p2pfirstAddress[betid] =_token;
    }


    function p2pSaveFinalise(string calldata betid, address reciever, uint amount, uint newamount, uint fee, bool last) external{
        require(msg.sender == p2pCaller, "You are not allowed to call");
        
        p2pBetidToClaimed[reciever][betid] = true;        
        delete p2pBetidToStake[reciever][betid];

        P2PBetIdtoTotal[betid] -= amount;

        adminTotaFee[p2pTokenToStake[msg.sender][betid]] += fee;

        p2pLastClaim(p2pTokenToStake[msg.sender][betid], betid, last, P2PBetIdtoTotal[betid]);

              
        if (bonus == true && p2pTokenToStake[msg.sender][betid] == bonusAddress){
          p2pBonus(newamount, betid, reciever);
        }

   }

    function p2pBonus(uint amount, string calldata betid, address reciever) internal{
        

         amount = amount * bonusPercent/ 10000;
         if(amount > maxBonusAmount){

             amount = maxBonusAmount;
         }

        normalTransfer(p2pTokenToStake[reciever][betid], reciever, amount);

    }

   
  function p2pLastClaim(address _token, string calldata betid, bool last, uint residual) internal{
        p2pfullyClaimed[betid] = last;

        if(p2pfullyClaimed[betid]){
            totalResiduals[_token] += residual;
        }
    }

    
        
    function _p2pGetStaked(string calldata  betid, address staker) external view returns(bool){
        require(msg.sender == p2pCaller, "You are not allowed to call");
        return p2pStaked[staker][betid];
    }

    function _p2pGetFinalised(string calldata  betid, address reciever) external view returns(bool){
        require(msg.sender == p2pCaller, "You are not allowed to call");
        return p2pBetidToClaimed[reciever][betid];
    }

    function p2pGetStake(string calldata betid, address staker) external view returns(uint){
        require(msg.sender == p2pCaller, "You are not allowed to call");
        return p2pBetidToStake[staker][betid];
    }
    function p2pGetTotalStake(string calldata betid) external view returns(uint){
        require(msg.sender == p2pCaller, "You are not allowed to call");
        return P2PBetIdtoTotal[betid];
    } 
    function _p2pGetTokenToStake(string calldata betid, address reciever) external view returns(address){
        require(msg.sender == p2pCaller, "You are not allowed to call");
        return p2pTokenToStake[reciever][betid];
    }
    function getBetCount(string calldata betid) external view returns(uint){
        require(msg.sender == p2pCaller, "You are not allowed to call");
        return p2pBetCount[betid];
    }
    function getFirstAddress(string calldata betid) external view returns (address){
        require(msg.sender == p2pCaller, "You are not allowed to call");
        return p2pfirstAddress[betid];
    }














  ////////////////////////////////////////////////////
  ////////////////////////////////////////////////////
  ////////////////////////////////////////////////////
  ////////////////POOL FUNCTIONS//////////////////////
  ////////////////////////////////////////////////////
  ////////////////////////////////////////////////////







    mapping(address => mapping(string => mapping(uint => uint))) public poolBetidToStake;
    mapping(address => mapping(string => mapping(uint => address))) public poolTokenToStake;
    mapping(string => uint) public poolBetIdtoTotal;
    mapping(string => uint) public poolBetCount;
    mapping(address => mapping(string => mapping(uint => bool))) public poolBetidToClaimed;
    mapping(address => mapping(string => mapping(uint => bool))) public poolStaked;
    mapping(string => bool) public poolFullyClaimed;
    mapping(string => string) public poolGame;
    mapping(string => address) public poolFirstAddress;

    mapping(string => address) public poolfirstAddress;
    mapping(string => bool) public poolBetidStored;
    mapping(uint => string) public poolIndextoBetid;
    uint public poolBetidNumber;

    string[] public poolBetidArray;



    
    function poolSaveStakeData(address _token, address staker, string calldata  betid,uint transactionID, uint stakeAmount, string calldata game) external{
            require(msg.sender == poolCaller, "You are not allowed to call");

            
            if(!poolBetidStored[betid]){
                poolBetidStored[betid] = true;
                poolBetidNumber++;   
                poolBetidArray.push(betid);
                poolIndextoBetid[poolBetidNumber];

            }

            poolBetidToStake[staker][betid][transactionID] += stakeAmount;
            poolBetIdtoTotal[betid] += stakeAmount;
            poolBetCount[betid] +=1;
            poolTokenToStake[staker][betid][transactionID] = _token;

            
            poolStaked[staker][betid][transactionID] = true;

            poolGame[betid] = game;

    }



    function setPoolFirstAddress(address _token, string calldata betid) external{
        require(msg.sender == poolCaller, "You are not allowed to call");
        poolFirstAddress[betid] =_token;
    }

function poolSaveFinalise(string calldata betid, uint transactionID, address reciever, uint amount, uint newamount, uint fee, bool last) external{
        require(msg.sender == poolCaller, "You are not allowed to call");
        poolBetidToClaimed[reciever][betid][transactionID] = true;        
        delete poolBetidToStake[reciever][betid][transactionID];

        poolBetIdtoTotal[betid] -= amount;

        adminTotaFee[poolTokenToStake[reciever][betid][transactionID]] += fee;

        poolLastClaim(poolTokenToStake[reciever][betid][transactionID], betid, last, poolBetIdtoTotal[betid]);

              
        if (bonus == true && poolTokenToStake[reciever][betid][transactionID] == bonusAddress){
          poolBonus(newamount, reciever);
        }

   }

    function poolBonus(uint amount, address reciever) internal{
        

         amount = amount * bonusPercent/ 10000;
         if(amount > maxBonusAmount){

             amount = maxBonusAmount;
         }

        normalTransfer(bonusAddress, reciever, amount);

    }

   
  function poolLastClaim(address _token, string calldata betid, bool last, uint residual) internal{
        poolFullyClaimed[betid] = last;

        if(poolFullyClaimed[betid]){
            totalResiduals[_token] += residual;
        }
    }

    
        
    function _poolGetStaked(string calldata  betid, uint transactionID, address staker) external view returns(bool){
        require(msg.sender == poolCaller, "You are not allowed to call");
        return poolStaked[staker][betid][transactionID];
    }

    function _poolGetFinalised(string calldata  betid, uint transactionID, address reciever) external view returns(bool){
        require(msg.sender == poolCaller, "You are not allowed to call");
        return poolBetidToClaimed[reciever][betid][transactionID];
    }

    function poolGetStake(string calldata betid, uint transactionID, address staker) external view returns(uint){
        require(msg.sender == poolCaller, "You are not allowed to call");
        return poolBetidToStake[staker][betid][transactionID];
    }
    function poolGetTotalStake(string calldata betid) external view returns(uint){
        require(msg.sender == poolCaller, "You are not allowed to call");
        return poolBetIdtoTotal[betid];
    } 
    function _poolGetTokenToStake(string calldata betid, uint transactionID, address reciever) external view returns(address){
        require(msg.sender == poolCaller, "You are not allowed to call");
        return poolTokenToStake[reciever][betid][transactionID];
    }
    function getPoolBetCount(string calldata betid) external view returns(uint){
        require(msg.sender == poolCaller, "You are not allowed to call");
        return poolBetCount[betid];
    }
    function getPoolFirstAddress(string calldata betid) external view returns (address){
        require(msg.sender == poolCaller, "You are not allowed to call");
        return poolFirstAddress[betid];
    }



















  ////////////////////////////////////////////////////
  ////////////////////////////////////////////////////
  ////////////////////////////////////////////////////
  ///////////////ADMIN FUNCTIONS//////////////////////
  ////////////////////////////////////////////////////
  ////////////////////////////////////////////////////



    
    mapping (address => uint) public adminTotaFee;
    mapping (address => uint) public totalResiduals;

    bool public bonus;
    uint public bonusPercent;
    uint public maxBonusAmount;
    address public bonusAddress;
    address p2pCaller;
    address poolCaller;
    address extraCaller;
    address migrator;

    function getTotalResidue(address _token) external view returns(uint){
          require(msg.sender == admin, "Not Admin");
        return totalResiduals[_token];
    }


            
     function withdrawFees(address _token, uint amount) external{
        require(msg.sender == admin, "Not Admin");
        require(amount <= adminTotaFee[_token], "Insufficient Amount in Balance");

        IERC20Upgradeable token = IERC20Upgradeable(_token);
        adminTotaFee[_token] -= amount;

        token.transfer(admin, amount);

        
    }
    
    function adminResidualWithdraw(address _token) external{
          require(msg.sender == admin, "Not Admin");
          require(totalResiduals[_token] > 0, "No Residuals Available");
        
        IERC20Upgradeable token = IERC20Upgradeable(_token);

          uint residual = totalResiduals[_token];

          delete totalResiduals[_token];

          token.transfer(admin, residual);
    }

    function setBonus(bool _bonus) external{
        require(msg.sender == admin, "Not Admin");

        bonus = _bonus;
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


    function setPoolCaller(address caller) external{
        require(msg.sender == admin, "Not Admin");
        poolCaller = caller;

    }
    
    function setExtraCaller(address caller) external{
        require(msg.sender == admin, "Not Admin");
        extraCaller = caller;

    }

    function setMigrator(address _migrator) external{
        require(msg.sender == admin, "Not Admin");
        migrator = _migrator;
    }


    function _Migrate() external{
        require(msg.sender == admin, "Not Admin");
        address tokenA = 0xe10DCe92fB554E057619142AbFBB41688A7e8D07;
        address tokenB = 0xb5708e2F641738312D51f824A46992Ae6c89D9f5;

        IERC20Upgradeable token = IERC20Upgradeable(tokenA);

        
        normalTransfer(tokenA, migrator, token.balanceOf(address(this)));


        IERC20Upgradeable token2 = IERC20Upgradeable(tokenB);

        normalTransfer(tokenB, migrator, token2.balanceOf(address(this)));


    }


}