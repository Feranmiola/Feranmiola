// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./database.sol";

contract LogicPool is Initializable{

    address public admin;
    database public dataStorage;

    address public tokenA;
    address public tokenB;
    
    bool public isContractPaused;

    event GameName(string gamename);
    

    function initialize() external initializer{
        admin = payable(msg.sender);
        // token = IERC20(0xe10DCe92fB554E057619142AbFBB41688A7e8D07);
        tokenA = 0xe10DCe92fB554E057619142AbFBB41688A7e8D07;
        tokenB = 0xb5708e2F641738312D51f824A46992Ae6c89D9f5;
        dataStorage;

    }
    


    receive() external payable{}

    function _poolStake(address _token, uint stakeAmount, address staker) internal returns(bool success){
            
            IERC20Upgradeable token = IERC20Upgradeable(_token);

            token.transferFrom(staker, address(dataStorage), stakeAmount);
            
            return true;
        
    }

    

    function Stake(address _token, string calldata  betid, string calldata game, uint transactionID, uint stakeAmount) external{
        // require(!poolFullyClaimed[betid], "Bet Id is currently in use");
        require(!isContractPaused, "Contract is paused");
        if (_token == tokenA || _token == tokenB){
            
            if(dataStorage.getPoolBetCount(betid) == 0){
                    dataStorage.setPoolFirstAddress(_token, betid);
                    
                }else{
                    
                    require(_token == dataStorage.getPoolFirstAddress(betid), "Token not used in bet");
                    
            }

            bool success = _poolStake(_token, stakeAmount, msg.sender);

            require(success, "transfer Failed");


            dataStorage.poolSaveStakeData(_token, msg.sender, betid, transactionID, stakeAmount, game);


            emit GameName(game);

        }else{
            revert("Unknown Token");
        }

     

    }

    function creditsStake(address _token, string calldata  betid, string calldata game, uint transactionID, uint stakeAmount) external{
         if (_token == tokenA || _token == tokenB){
            
            if(dataStorage.getPoolBetCount(betid) == 0){
                    dataStorage.setPoolFirstAddress(_token, betid);
                    
                }else{
                    
                    require(_token == dataStorage.getPoolFirstAddress(betid), "Token not used in bet");
                    
            }


            dataStorage.poolSaveStakeData(_token, msg.sender, betid, transactionID, stakeAmount, game);

   
            emit GameName(game);

        }else{
            revert("Unknown Token");
        }


    }

    function getpoolStaked(string calldata  betid, uint transactionID, address staker) external view returns(bool){
        return dataStorage._poolGetStaked(betid, transactionID, staker);
    }

    function getFinalised(string calldata  betid, uint transactionID, address reciever) public view returns(bool){
        return dataStorage._poolGetFinalised(betid, transactionID, reciever);
    }




    function end(string calldata  betid, uint transactionID, uint amount, uint fee, bool last) external{
        
        require(!getFinalised(betid, transactionID, msg.sender), "Address already claimed");
        
        uint stake = dataStorage.poolGetStake(betid, transactionID, msg.sender);
        uint totalStake = dataStorage.poolGetTotalStake(betid);

        require(amount <= totalStake, "Insufficient Amount in balance");
        require(stake > 0, "Did Not Stake");
         
        uint newamount = amount;
        
        bool success = dataStorage._transfer(dataStorage._poolGetTokenToStake(betid, transactionID, msg.sender), msg.sender, amount);
        require(success, "Transfer Not Successful");
        
        
        amount+= fee;

        dataStorage.poolSaveFinalise(betid, transactionID, msg.sender, amount, newamount, fee, last);
        
        

    }

  function setDataStorage(address newStorage) external{
        require(msg.sender == admin, "Not Admin");
        require(isContractPaused, "Pause the contract first");

        dataStorage = database(newStorage);
    }

    function pauseContract(bool pause) external{
        require(msg.sender == admin, "Not Admin");
        isContractPaused = pause;
    }

    
}
