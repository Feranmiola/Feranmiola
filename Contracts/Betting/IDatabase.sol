// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface iDatabase {
    
    function _transfer(address _token, address reciever, uint amount) external returns(bool);

    function SaveStakeData(address _token, address staker, string calldata  betid,uint transactionID, uint stakeAmount, string calldata game) external;
    function setFirstAddress(address _token, string calldata betid) external;
    function SaveFinalise(string calldata betid, uint transactionID, address reciever, uint amount, uint newamount, uint fee, bool last) external;
    //Getters

    function _GetStaked(string calldata  betid, uint transactionID, address staker) external view returns(bool);
    function _GetFinalised(string calldata  betid, uint transactionID, address reciever) external view returns(bool);
    function GetStake(string calldata betid, uint transactionID, address staker) external view returns(uint);
    function GetTotalStake(string calldata betid) external view returns(uint);
    function _GetTokenToStake(string calldata betid, uint transactionID, address reciever) external view returns(address);
    function getBetCount(string calldata betid) external view returns(uint);
    function getFirstAddress(string calldata betid) external view returns (address);
    function getbetidStored(string calldata betid) external view returns(bool);

    function getAdmin() external view returns(address);
    function getTokenA() external view returns(address);
    function getTokenB() external view returns(address);


}