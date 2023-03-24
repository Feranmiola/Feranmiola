// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./IDatabase.sol";

contract LogicPool is Initializable{

    iDatabase public dataStorage;

    address public tokenA;
    address public tokenB;
    
    bool public isContractPaused;

    event GameName(string gamename);
    
    function initialize(address _database) external initializer{
        
        dataStorage = iDatabase(_database);

        tokenA = dataStorage.getTokenA();
        tokenB = dataStorage.getTokenB();

    }
    


    receive() external payable{}

    function _Stake(address _token,  uint stakeAmount, address staker) internal returns(bool success){
            IERC20Upgradeable token = IERC20Upgradeable(_token);

            token.transferFrom(staker, address(dataStorage), stakeAmount);

            return true;
        
    }
    

    function PoolnotP2P_Stake(address _token, string calldata  betid, string calldata game, uint transactionID, uint stakeAmount) external{
      require(!isContractPaused, "Contract is paused");
      if (_token == tokenA || _token == tokenB){
            
            if(dataStorage.getBetCount(betid) == 0){
                    dataStorage.setFirstAddress(_token, betid);
                    
                }else{
                    
                    require(_token == dataStorage.getFirstAddress(betid), "Token not used in bet");
                    
            }

            bool success = _Stake(_token, stakeAmount, msg.sender);

            require(success, "transfer Failed");

            dataStorage.SaveStakeData(_token, msg.sender, betid, transactionID, stakeAmount, game);

   
            emit GameName(game);

        }else{
            revert("Unknown Token");
        }
     

    }

    function PoolnotP2P_creditsStake(address _token, string calldata  betid, string calldata game, uint transactionID, uint stakeAmount) external{
         require(!isContractPaused, "Contract is paused");
         if (_token == tokenA || _token == tokenB){
            
            if(dataStorage.getBetCount(betid) == 0){
                    dataStorage.setFirstAddress(_token, betid);
                    
                }else{
                    
                    require(_token == dataStorage.getFirstAddress(betid), "Token not used in bet");
                    
            }


            dataStorage.SaveStakeData(_token, msg.sender, betid, transactionID, stakeAmount, game);

   
            emit GameName(game);

        }else{
            revert("Unknown Token");
        }


    }

    function PoolnotP2P_getStaked(string calldata  betid, uint transactionID, address staker) external view returns(bool){
        return dataStorage._GetStaked(betid, transactionID, staker);
    }

    function PoolnotP2P_getFinalised(string calldata  betid, uint transactionID, address reciever) public view returns(bool){
        return dataStorage._GetFinalised(betid, transactionID, reciever);
    }




    function PoolnotP2P_end(string calldata  betid, uint transactionID, uint amount, uint fee, bool last) external{
        require(!isContractPaused, "Contract is paused");
        require(!PoolnotP2P_getFinalised(betid, transactionID, msg.sender), "Address already claimed");
        
        uint stake = dataStorage.GetStake(betid, transactionID, msg.sender);
        uint totalStake = dataStorage.GetTotalStake(betid);

        require(dataStorage.getbetidStored(betid), "BetId not used");
        require(amount <= totalStake, "Insufficient Amount in balance");
        require(stake > 0, "Did Not Stake");
         
        uint newamount = amount;
        
        bool success = dataStorage._transfer(dataStorage._GetTokenToStake(betid, transactionID, msg.sender), msg.sender, amount);
        require(success, "Transfer Not Successful");
        
        
        amount+= fee;

        dataStorage.SaveFinalise(betid, transactionID, msg.sender, amount, newamount, fee, last);

    }

    function PoolnotP2P_setDataStorage(address newStorage) external{
        require(msg.sender == dataStorage.getAdmin(), "Not Admin");
        require(isContractPaused, "Pause the contract first");

        dataStorage = iDatabase(newStorage);
    }

    function dataStorageCaller_pauseContract() external{
        require(msg.sender == address(dataStorage), "Not Database");
       
        if(isContractPaused){
         isContractPaused = false;   
        } else{
            isContractPaused = true;
        }
    }
    function dataStorageCaller_changeTokenA(address _newTokenA) external{
        require(msg.sender == address(dataStorage), "Not Database");

        tokenA = _newTokenA;

    }

    function dataStorageCaller_changeTokenB(address _newTokenB) external{
        require(msg.sender == address(dataStorage), "Not Database");

        tokenB = _newTokenB;

    }

    
    
}
