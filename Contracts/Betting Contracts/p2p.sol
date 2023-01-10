// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./database.sol";

contract LogicP2P is Initializable{
    address public admin;
    database public dataStorage;
    
    address public tokenA;
    address public tokenB;

    bool public isContractPaused;

    event GameName(string gamename);


    function initialize() external initializer{
        admin = payable(msg.sender);
        // token = IERC20(0x11d1149202fbb7eeeA118BCEb85db1D7eAA3084A);
        tokenA = 0xe10DCe92fB554E057619142AbFBB41688A7e8D07;
        tokenB = 0xb5708e2F641738312D51f824A46992Ae6c89D9f5;
        dataStorage;
        

    }
    
    

    receive() external payable{}

    
    function _p2pStake(address _token,  uint stakeAmount, address staker) internal returns(bool success){
            IERC20Upgradeable token = IERC20Upgradeable(_token);

            token.transferFrom(staker, address(dataStorage), stakeAmount);

            return true;
        
    }
    
  
    function Stake(address _token, string calldata  betid, string calldata game, uint stakeAmount) external{
        // require(!fullyClaimed[betid], "Bet Id is currently in use");
        require(!isContractPaused, "Contract is paused");
         if (_token == tokenA || _token == tokenB){

            if(dataStorage.getBetCount(betid) == 0){
                    dataStorage.setP2PFirstAddress(_token, betid);
                    
                }else{
                    
                    require(_token == dataStorage.getFirstAddress(betid), "Token not used in bet");
                    
            }

            bool success = _p2pStake(_token, stakeAmount, msg.sender);

            require(success, "transfer Failed");

            dataStorage.p2pSaveStakeData(_token, msg.sender, betid, stakeAmount, game);

 
            emit GameName(game);

            
        }else{
            revert("Unknown Token");
        }
        
    }



    function  creditsStake(address _token, string calldata  betid, string calldata game, uint stakeAmount) external{
        require(!isContractPaused, "Contract is paused");
        // require(!fullyClaimed[betid], "Bet Id is currently in use");

         if (_token == tokenA || _token == tokenB){
             if (_token == tokenA || _token == tokenB){

                if(dataStorage.getBetCount(betid) == 0){
                    
                        dataStorage.setP2PFirstAddress(_token, betid);
                        
                    }else{
                        
                        require(_token == dataStorage.getFirstAddress(betid), "Token not used in bet");
                        
                }

     
            dataStorage.p2pSaveStakeData(_token, msg.sender, betid, stakeAmount, game);
    
            emit GameName(game);

            
        }else{
            revert("Unknown Token");
        }
    }
}


        
    function getStaked(string calldata  betid, address staker) external view returns(bool){
        return dataStorage._p2pGetStaked(betid, staker);
    }

    function getFinalised(string calldata  betid, address reciever) public view returns(bool){
        return dataStorage._p2pGetFinalised(betid, reciever);
    }




    function end(string calldata  betid, uint amount, uint fee, bool last) external{
        require(!isContractPaused, "Contract is paused");
        require(!getFinalised(betid, msg.sender), "Address already claimed");

        uint stake = dataStorage.p2pGetStake(betid, msg.sender);

        uint totalStake = dataStorage.p2pGetTotalStake(betid);

        
        require(amount <= totalStake, "Insufficient Amount in balance");//Insufficient amount
        require(stake > 0, "Did Not StakeS");//DId not stake
        
        uint newamount = amount;
        
        bool success = dataStorage._transfer(dataStorage._p2pGetTokenToStake(betid, msg.sender), msg.sender, amount);

        require(success, "Transfer Not Successful");
        
        amount+= fee;

        dataStorage.p2pSaveFinalise(betid, msg.sender, amount, newamount, fee, last);


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