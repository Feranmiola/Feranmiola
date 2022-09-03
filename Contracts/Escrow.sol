//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract escrow{

    address immutable admin;

    constructor() {
        admin = payable(msg.sender);     
    }

    struct Escrow{
        bool active;
        address sender;
        address reciever;
        address token;
        uint256 recieverExpectedTokenAmount;
        uint256 recieverRecievedTokenAmount;
        uint256 senderExpectedEthAmount;
        uint256 senderRecievedEthAmount;
        bool tokenSent;
        bool ethSent;
        bool closed;
    }
    Escrow escrowg;

    struct SignCancel{
        bool senderSigned;
        bool recieverSIgned;
    }
    SignCancel signCancel;

    mapping(uint => Escrow) public IdtoEscrow;
    mapping(address => uint) public addressToId;
    mapping(uint => SignCancel) public idtoCancelSignature;

    uint256 escrowCount;

    //Fees

    uint256 Escrowfee;
    uint256 totalEscrowFeeTaken;
    uint256 CancellationFee;
    mapping(address => uint) public totaltokenFeeTaken;



        //////////////////////////////////////////////////////////
        //////////////////////////////////////////////////////////


//Admin Functions
    modifier onlyAdmin{
        require(msg.sender == admin, "NA");//Not Admin
        _;
    }

    function setFees(uint _escrowFee, uint _cancellationFee) external onlyAdmin{
        Escrowfee = _escrowFee;
        CancellationFee = _cancellationFee;
    }

    
        //////////////////////////////////////////////////////////
        //////////////////////////////////////////////////////////

    //Main Transac functions 

    function startTransac(address _sender, address _receiver, address _token, uint256 expectedToken, uint256 expectedEth) external {
        escrowCount++;
        IdtoEscrow[escrowCount] = Escrow({
            active : true,
            sender : _sender,
            reciever : _receiver,
            token : _token,
            recieverExpectedTokenAmount : expectedToken,
            recieverRecievedTokenAmount : 0,
            senderExpectedEthAmount : expectedEth,
            senderRecievedEthAmount : 0,
            tokenSent : false,
            ethSent : false,
            closed : false
        });

        addressToId[_sender] = escrowCount;
        addressToId[_receiver] = escrowCount;

    }


    function sendToken(uint256 amount) external{
        uint escrowid = addressToId[msg.sender];

        require(IdtoEscrow[escrowid].active, "NA");//Not Active

        require(msg.sender == IdtoEscrow[escrowid].reciever,"RCSEth");//Sender cant send tokens cant send eth

        require(IdtoEscrow[escrowid].recieverExpectedTokenAmount <= amount);

        IERC20 _token = IERC20(IdtoEscrow[escrowid].token);

        _token.approve(address(this), amount);
        _token.transferFrom(msg.sender, address(this), amount);

        IdtoEscrow[escrowid].recieverRecievedTokenAmount += amount;

        IdtoEscrow[escrowid].tokenSent = true;
    }

    receive() external payable{
        sendEth();
    }
    function sendEth() public payable {
        
        uint escrowid = addressToId[msg.sender];

        require(IdtoEscrow[escrowid].active, "NA");//Not Active

        require(msg.sender == IdtoEscrow[escrowid].sender,"RCSEth");//Reciever cant send eth

        require(IdtoEscrow[escrowid].tokenSent, "TNS");//token not sent
        require(msg.value >= IdtoEscrow[escrowid].senderExpectedEthAmount, "NEE");//not enough eth

        IdtoEscrow[escrowid].senderRecievedEthAmount += msg.value;

        IdtoEscrow[escrowid].ethSent = true;
    }

    function finalise() external{
         uint escrowid = addressToId[msg.sender];

        require(IdtoEscrow[escrowid].active, "NA");//Not Active
    
        require(!IdtoEscrow[escrowid].closed, "AC");//Already closed

        require(IdtoEscrow[escrowid].ethSent, "ENS");//Eth not sent
        require(IdtoEscrow[escrowid].tokenSent, "TNS");//Token not sent

        IERC20 token = IERC20(IdtoEscrow[escrowid].token);

        uint fee = Escrowfee * IdtoEscrow[escrowid].recieverExpectedTokenAmount /10000;

        uint amount = IdtoEscrow[escrowid].recieverExpectedTokenAmount - fee;

        totaltokenFeeTaken[IdtoEscrow[escrowid].token] += fee;

        token.transfer(IdtoEscrow[escrowid].sender, amount);
        token.transfer(admin, fee);

        uint fee2 = Escrowfee * IdtoEscrow[escrowid].senderExpectedEthAmount /10000;

        uint amount2 = IdtoEscrow[escrowid].senderExpectedEthAmount - fee2;

        totalEscrowFeeTaken +=fee2;

        payable(IdtoEscrow[escrowid].reciever).transfer(amount2);
        payable(admin).transfer(fee2);
      
        if(IdtoEscrow[escrowid].senderExpectedEthAmount < IdtoEscrow[escrowid].senderRecievedEthAmount){
            IdtoEscrow[escrowid].senderRecievedEthAmount -= IdtoEscrow[escrowid].senderExpectedEthAmount;

            payable(IdtoEscrow[escrowid].sender).transfer(IdtoEscrow[escrowid].senderRecievedEthAmount);
        }

        if(IdtoEscrow[escrowid].recieverExpectedTokenAmount < IdtoEscrow[escrowid].recieverRecievedTokenAmount){
            IdtoEscrow[escrowid].recieverRecievedTokenAmount -= IdtoEscrow[escrowid].recieverExpectedTokenAmount;

            token.transfer(IdtoEscrow[escrowid].reciever, IdtoEscrow[escrowid].recieverRecievedTokenAmount);
        }
        
          IdtoEscrow[escrowid].closed = true;
          IdtoEscrow[escrowid].active = false;

    }


        //////////////////////////////////////////////////////////
        //////////////////////////////////////////////////////////


    //Cancel transaction functions 
    
    function cancelSenderSign() external {
        uint escrowid = addressToId[msg.sender];

        require(IdtoEscrow[escrowid].active, "NA");//Not Active

        require(msg.sender == IdtoEscrow[escrowid].sender,"NS");//Not Sender

        idtoCancelSignature[escrowid].senderSigned = true;
      
    }

    function cancelRecieverSign() external {
        uint escrowid = addressToId[msg.sender];

        require(IdtoEscrow[escrowid].active, "NA");//Not Active

        require(msg.sender == IdtoEscrow[escrowid].reciever,"NR");//Not Reciever

        idtoCancelSignature[escrowid].senderSigned = true;
    }

    function cancelTransac() external{
      uint escrowid = addressToId[msg.sender];

      require(IdtoEscrow[escrowid].active, "NA");//Not Active
      
      require(idtoCancelSignature[escrowid].senderSigned, "SNS");//Sender not signed
      require(idtoCancelSignature[escrowid].recieverSIgned, "RNS");//Reciever not signed

      IdtoEscrow[escrowid].closed = true;
      IdtoEscrow[escrowid].active = false;

      if(IdtoEscrow[escrowid].recieverRecievedTokenAmount > 0){
            IERC20 _token = IERC20(IdtoEscrow[escrowid].token);

            uint Fee = CancellationFee * IdtoEscrow[escrowid].recieverRecievedTokenAmount/10000;

            uint amount = IdtoEscrow[escrowid].recieverRecievedTokenAmount - Fee;

            totaltokenFeeTaken[IdtoEscrow[escrowid].token] += Fee;

            _token.transfer(IdtoEscrow[escrowid].reciever, amount);
            _token.transfer(admin, Fee);

            delete IdtoEscrow[escrowid].recieverRecievedTokenAmount;
      }

      if(IdtoEscrow[escrowid].senderRecievedEthAmount > 0){

          uint fee = IdtoEscrow[escrowid].senderRecievedEthAmount * CancellationFee /10000;

          uint amount = IdtoEscrow[escrowid].senderRecievedEthAmount - fee;

          totalEscrowFeeTaken += fee;

          payable(IdtoEscrow[escrowid].sender).transfer(amount);
          payable(admin).transfer(fee);
          delete IdtoEscrow[escrowid].senderRecievedEthAmount;
      }
      
    }


        //////////////////////////////////////////////////////////
        //////////////////////////////////////////////////////////

    //Getter Functions

    function isActive() external view returns(bool){
        
        uint escrowid = addressToId[msg.sender];

        return IdtoEscrow[escrowid].active;

    }

    function getsender() external view returns(address){
        uint escrowid = addressToId[msg.sender];

        return IdtoEscrow[escrowid].sender;

    }

    function getReciever() external view returns(address){
        uint escrowid = addressToId[msg.sender];

        return IdtoEscrow[escrowid].reciever;

    }

    function getRquiredTokens() external view returns(uint){
        uint escrowid = addressToId[msg.sender];

        return IdtoEscrow[escrowid].recieverExpectedTokenAmount;

    }

    function getRecievedTokens() external view returns(uint){
        uint escrowid = addressToId[msg.sender];

        return IdtoEscrow[escrowid].recieverRecievedTokenAmount;
    }

    function getrequiredEth() external view returns(uint){
            uint escrowid = addressToId[msg.sender];

        return IdtoEscrow[escrowid].senderExpectedEthAmount;

    }

    function getRecievedEth() external view returns(uint){
         uint escrowid = addressToId[msg.sender];

        return IdtoEscrow[escrowid].senderRecievedEthAmount;
    }

    function EthPaid() external view returns(bool){
          uint escrowid = addressToId[msg.sender];

        return IdtoEscrow[escrowid].ethSent;
    }

    function tokenPaid() external view returns(bool){
         uint escrowid = addressToId[msg.sender];

        return IdtoEscrow[escrowid].tokenSent;
    }

    function TransactionComplete() external view returns(bool){
         uint escrowid = addressToId[msg.sender];

        return IdtoEscrow[escrowid].tokenSent;
    }


}
