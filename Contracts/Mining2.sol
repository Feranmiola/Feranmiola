// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract setup{

    address immutable admin;

    struct NewToken{
        address token;
        address creator;
        uint maxSupply;
        uint initSupply;
        uint currentSupply;
        uint claimedSupply;
        uint maxClaimmable;
        uint claimInterval;
        uint mineFee;
        uint mineUnit;
        uint MinedEth;
        bool ended;
    }

    uint tokenIndex;

    mapping(uint => NewToken) indextoToken;
    mapping(address => uint) creatorToToken;

    //Fees 
    uint tokenFee;
    uint ethFee;

    constructor() {
        admin = payable(msg.sender);
    }

    function setFees(uint _tokenFee, uint _ethfee) external{
        require(msg.sender == admin, "NA");//Not admin

        tokenFee = _tokenFee;
        ethFee = _ethfee;
    }



    function addNewToken(address _token, uint _maxsupply, uint _initSupply, uint _mineUint, uint _maxclaimmable, uint _claiminterval, uint _mineFee) external {
        require(msg.sender != address(0), "EA");//Error Address

        tokenIndex++;
        
        IERC20 token = IERC20(_token);  
        uint Amount = _initSupply += (tokenFee * _initSupply/10000);

        token.approve(address(this), Amount);
        token.transferFrom(msg.sender, address(this), Amount);
        uint fee = Amount - _initSupply;

        token.transfer(admin, fee);

        indextoToken[tokenIndex] = NewToken({
            token : _token,
            creator : msg.sender,
            maxSupply : _maxsupply,
            initSupply : _initSupply,
            currentSupply : _initSupply,
            claimedSupply : 0,
            mineUnit : _mineUint,
            maxClaimmable : _maxclaimmable,
            claimInterval : _claiminterval,
            mineFee : _mineFee,
            MinedEth : 0,
            ended : false
        });

        creatorToToken[msg.sender] = tokenIndex;

        
        
    }


    function cancel() external {
        uint id = creatorToToken[msg.sender];

        indextoToken[id].ended = true;

        if( indextoToken[id].initSupply > 0 ){
            IERC20 token = IERC20(indextoToken[id].token);

            token.transfer(msg.sender, indextoToken[id].initSupply);

            delete indextoToken[id];
        }
    }

    function creatorWithdrawal(uint amount) external{
        uint id = creatorToToken[msg.sender];

        require(!indextoToken[id].ended, "ME");//Mining Ended
        require(amount < indextoToken[id].currentSupply, "IB");//Insufficient balance

         IERC20 token = IERC20(indextoToken[id].token);

            token.transfer(msg.sender, amount);

            indextoToken[id].currentSupply -= amount;
    }


    function Deposit(uint amount) external{
        uint id = creatorToToken[msg.sender];

        require(!indextoToken[id].ended, "ME");//Mining Ended
        require(indextoToken[id].currentSupply < indextoToken[id].maxSupply, "MR");//Max reached

        uint newAmount = amount + indextoToken[id].currentSupply;

        require(newAmount <= indextoToken[id].maxSupply, "TM");//Too much

        indextoToken[id].currentSupply += amount;

          
        IERC20 token = IERC20(indextoToken[id].token);  

        token.approve(address(this), amount);
        token.transferFrom(msg.sender, address(this), amount);

    }

    function FinaliseMining() external{
        uint id = creatorToToken[msg.sender];

        require(!indextoToken[id].ended, "ME");//Mining Ended

        if(indextoToken[id].claimedSupply > 0){
            uint fee = indextoToken[id].MinedEth * ethFee /10000;
            indextoToken[id].MinedEth -= fee;
            payable(indextoToken[id].creator).transfer(indextoToken[id].MinedEth);
            payable(admin).transfer(fee);
        }
        

        if(indextoToken[id].claimedSupply < indextoToken[id].currentSupply){
             IERC20 token = IERC20(indextoToken[id].token);

             uint amount = indextoToken[id].currentSupply - indextoToken[id].claimedSupply;

            token.transfer(msg.sender, amount);
            
        }

        indextoToken[id].ended = true; 

        delete indextoToken[id];
    }

    //Edit info

    ////////////////////////////////////////////////
    ///////////////////////////////////////////////

    
    function increasemaxSupply(uint newSupply) external {
        uint id = creatorToToken[msg.sender];

        require(!indextoToken[id].ended, "ME");//Mining Ended
        require(indextoToken[id].maxSupply > 0, "NE");//Not existing 
        require(indextoToken[id].maxSupply <= newSupply, "TMOAE");//Too much or already existing 

        indextoToken[id].maxSupply = newSupply;
    
    }

    function changeToken(address newtoken) external{
        uint id = creatorToToken[msg.sender];
        require(newtoken != indextoToken[id].token);
        require(indextoToken[id].MinedEth == 0, "TAB");//token alredy bought

        if(indextoToken[id].currentSupply > 0){
            IERC20 token = IERC20(indextoToken[id].token);

            token.transfer(msg.sender, indextoToken[id].currentSupply);

        }

        indextoToken[id].token = newtoken;

        IERC20 _token = IERC20(newtoken);

        _token.approve(address(this), indextoToken[id].currentSupply);
        _token.transferFrom(msg.sender, address(this), indextoToken[id].currentSupply);

    }

    function changeMineUnit(uint newUnit) external{
        uint id = creatorToToken[msg.sender];
        require(!indextoToken[id].ended, "ME");//Mining Ended
        require(indextoToken[id].mineUnit != newUnit, "UAS");//Unit already set

        indextoToken[id].mineUnit = newUnit;
    }

    function changeClaimInterval(uint newInterval) external{
        uint id = creatorToToken[msg.sender];
        require(!indextoToken[id].ended, "ME");//Mining Ended
        require(indextoToken[id].claimInterval != newInterval, "UAS");//Unit already set

        indextoToken[id].claimInterval = newInterval;
    }

    function changeMaxClaimmable(uint newMaxClaimmable) external{

        uint id = creatorToToken[msg.sender];
        require(!indextoToken[id].ended, "ME");//Mining Ended
        require(indextoToken[id].maxClaimmable != newMaxClaimmable, "UAS");//Unit already set

        indextoToken[id].maxClaimmable = newMaxClaimmable;

    }

    function changeMineFee(uint newMineFee) external{
        uint id = creatorToToken[msg.sender];
        require(!indextoToken[id].ended, "ME");//Mining Ended
        require(indextoToken[id].mineFee != newMineFee, "UAS");//Unit already set

        indextoToken[id].mineFee = newMineFee;
    }


//
//




//

//



//

//





//Fees system
//ethCreationFees
//tokenCancellation fees

    mapping(address => uint) usertoId;
    mapping(address => mapping(uint => uint)) usertoPaidEth;
    mapping(address => mapping(uint => uint)) usertointerval;
    mapping(address => mapping(uint => uint)) updatedTime;
    mapping(address => mapping(address => uint)) claimedTokens;
    mapping(address => mapping(uint => bool)) useridtoclosed;
    mapping(address => mapping(uint => bool)) WIthdrawn;



    receive() external payable{
        
    }

    function JoinMinePool(uint id) public payable{
        require(!indextoToken[id].ended, "ME");//Mining Ended
        require(indextoToken[id].currentSupply > 0, "ZB");//Zero balance
        require(indextoToken[id].mineFee <= msg.value, "ENE");//Eth not enough

        usertoId[msg.sender] = id;

        updatedTime[msg.sender][id] = block.timestamp;
        usertointerval[msg.sender][id] = indextoToken[id].claimInterval;
        usertoPaidEth[msg.sender][id] +=msg.value;

        indextoToken[id].MinedEth +=msg.value;

    }


    function mine() external{
        uint id = usertoId[msg.sender];
        uint newtime = updatedTime[msg.sender][id] + usertointerval[msg.sender][id];
        require(!indextoToken[id].ended, "ME");//Mining Ended

        uint newAmount = claimedTokens[msg.sender][indextoToken[id].token] + indextoToken[id].mineUnit;
        uint available = indextoToken[id].currentSupply - indextoToken[id].claimedSupply;

        require(indextoToken[id].mineUnit <= available);

        require(newAmount <= indextoToken[id].maxClaimmable, "EL");//Exceeded limit

        require(newtime <= block.timestamp, "TNR");//Time not reached

        claimedTokens[msg.sender][indextoToken[id].token] += indextoToken[id].mineUnit;

        indextoToken[id].claimedSupply +=indextoToken[id].mineUnit;
        indextoToken[id].currentSupply -=indextoToken[id].mineUnit;

        updatedTime[msg.sender][id] = newtime;        

    }

    function cancelMine() external{
        uint id = usertoId[msg.sender];
        require(!WIthdrawn[msg.sender][id], "AW, CC");//Already withdrawn cant cancel

        require(!indextoToken[id].ended, "ME");//Mining Ended
        require(!useridtoclosed[msg.sender][id], "AC");//Already closed

        useridtoclosed[msg.sender][id] = true;
        indextoToken[id].claimedSupply -= claimedTokens[msg.sender][indextoToken[id].token];

        delete claimedTokens[msg.sender][indextoToken[id].token];
        delete usertointerval[msg.sender][id];
        delete updatedTime[msg.sender][id];
        delete usertoId[msg.sender];

        uint debit = usertoPaidEth[msg.sender][id];
        indextoToken[id].MinedEth -= debit;

        delete usertoPaidEth[msg.sender][id];

        payable(msg.sender).transfer(debit);


    }

    function withdraw(uint amount) external{
        uint id = usertoId[msg.sender];

        require(!indextoToken[id].ended, "ME");//Mining Ended
        require(!useridtoclosed[msg.sender][id], "AC");//Already closed
        require(amount < claimedTokens[msg.sender][indextoToken[id].token], "IB");//Insufficient balanace 

        claimedTokens[msg.sender][indextoToken[id].token] -= amount;

        IERC20 token = IERC20(indextoToken[id].token);

        WIthdrawn[msg.sender][id] = true;
        
        token.transfer(msg.sender, amount);


    }  

    function Finalise() external{
        uint id = usertoId[msg.sender];

        require(!indextoToken[id].ended, "ME");//Mining Ended

        IERC20 token = IERC20(indextoToken[id].token);

        uint debit = claimedTokens[msg.sender][indextoToken[id].token];

        delete claimedTokens[msg.sender][indextoToken[id].token];
        delete usertointerval[msg.sender][id];
        delete updatedTime[msg.sender][id];
        delete usertoId[msg.sender];

        if(usertoPaidEth[msg.sender][id] > indextoToken[id].mineFee){
            uint ethdebit = usertoPaidEth[msg.sender][id] - indextoToken[id].mineFee;

            payable(msg.sender).transfer(ethdebit);
        }

        delete usertoPaidEth[msg.sender][id];
        token.transfer(msg.sender, debit);
    }

        
}
