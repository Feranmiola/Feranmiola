//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./BasicStructs.sol";


interface IICO{
    function cancelPresale() external;
    function setIsKYCAndAudit(bool kyc,bool audit) external;
     function requestKYCandAudit() external view returns(address);
     function adminCancelPresale() external;
}

contract database is Initializable{ 
    address public admin;
    address public lockAddress;

    mapping(uint256 => ICOBase) public icoList;
    mapping(address => ICOBase) public icoAddressList;
    mapping(address => ICOparam) public presaleDetails;
    mapping(address => bool) public ICOExists;
    mapping(address => bool) public ICOActive;
    


    address[] public ongoingIcos;
    address[] public endedIcos;
    
    
    // Track the number of ico launched
    uint256 public lastIndex;

    mapping(address => bool) public updatePermitted;
    
    // mapping(address=>bool) public _canUpdate;
    address public DEAD;
    // Fee
    uint256 public adminWalletFee; 
    uint256 public stakingPoolFee;
    uint256 public burnFee;

    //// Post ICO Fees

    uint256 feesBNBPercent;
    uint256 ICOAdminWalletFees;
    uint256 ICOStakingPoolFees;

    // Burn Tracker
    uint256 public totalBurned;

    // Fee collection address
    address public stakingPoolAddress;

    
    address public SSN;



    mapping(address => bool) public requestedKYC;


    function initialize() external initializer{
        admin = payable(msg.sender);
        updatePermitted[admin] = true;

    }







    //Admin functions 

    function GrantAccess(address user) external{
        require(msg.sender == admin, "Not admin");
        updatePermitted[user] = true;
    }

    function revokeAccess(address user) external{
        require(msg.sender == admin, "Not admin");
        updatePermitted[user] = false;
    }

    function setLunchStakingPoolFee(uint _newStakingPoolFee) external{
        require(msg.sender == admin, "Not admin");
        stakingPoolFee = _newStakingPoolFee;
    }

    function setLunchAdminWalletFee(uint _newAdminWalletFee) external{
        require(msg.sender == admin, "Not admin");

        adminWalletFee = _newAdminWalletFee;
        
    }

    function setLunchBurnFee(uint _newBurnFee) external{
        require(msg.sender == admin, "Not admin");

        burnFee = _newBurnFee;
    }

    function setStakingPoolAddress(address _newStakingpoolAddress) external{
        require(updatePermitted[msg.sender], "Not allowed");
        stakingPoolAddress = _newStakingpoolAddress;
    }


    function updateKYCAndnAudit(address presale,bool kyc,bool audit) external{
        require(updatePermitted[msg.sender], "Not allowed");
        require(requestedKYC[presale], "PDNRKA");//Presake did not request KYA and AUdit

        IICO ico_ = IICO(presale);

        ico_.setIsKYCAndAudit(kyc,audit);
    }

    function cancelPresale(address presaleAddress) external{
        require(updatePermitted[msg.sender], "Not allowed");

        IICO ico = IICO(presaleAddress);

        ico.adminCancelPresale();

    }

    function setICOFeBNBPercente(uint _newFeeBNBPercent) external{
        require(msg.sender == admin, "Not admin");
    
        feesBNBPercent = _newFeeBNBPercent;

    }
    
    function setICOAdminWalletFee(uint _newICOAdminWalletFee) external {
        require(msg.sender == admin, "Not admin");

        ICOAdminWalletFees = _newICOAdminWalletFee;

    }
    
    function setICOStakingPoolFee(uint _newICOStakingPoolFee) external{
        require(msg.sender == admin, "Not admin");

        ICOStakingPoolFees = _newICOStakingPoolFee;
    }

    function setLockAddress(address _newLockerAddress) external{
        require(msg.sender == admin, "Not admin");

            lockAddress = _newLockerAddress;
    }

    function changeAdmin(address _newAdmin) external{
        require(msg.sender == admin, "Not admin");
        admin = _newAdmin;
    }

    function changeFeeToken(address _newtoken) external{
        require(msg.sender == admin, "Not admin");
        SSN = _newtoken;
    }

    






    function getPermitted(address user) external view returns(bool){
        return updatePermitted[user];
    }
    function getFeeToken() external view returns(address){
        return address(SSN);
    }
    function getAdmin() external view returns(address){
        return admin;
    }
    function getLunchStakingPoolFee() external view returns(uint){
        return stakingPoolFee;
    }
    function getLunchAdminWalletFee() external view returns(uint) {
        return adminWalletFee;
    }
    function getBurnFee() external view returns(uint) {
        return burnFee;
    }
    function getStakingPoolAddress() external view returns(address){
        return stakingPoolAddress;
    }
    function getFeesBNBPercent() external view returns(uint){
        return feesBNBPercent;
    }
    function getICOAdminWalletFee() external view returns(uint){
        return ICOAdminWalletFees;
    }
    function getICOStakingPoolFee() external view returns(uint){
        return ICOStakingPoolFees;
    }
    function getLockAddress() external view returns(address){
        return lockAddress;
    }





    //Lunchpad and Presale

    function setPresaleDetails(address presaleAddress, ICOparam memory icoData) external {
        ongoingIcos.push(presaleAddress);

        presaleDetails[presaleAddress] = icoData;

        ICOExists[presaleAddress] = true;
        ICOActive[presaleAddress] = true;

        lastIndex++;

        totalBurned += burnFee;
    }

    function endPresale() external{
        ICOActive[msg.sender] = false; 
        endedIcos.push(msg.sender);

    }




    function getLastIndex() external view returns(uint) {
        return lastIndex;
    }

    
    function requestKYCandAudit() external{
        requestedKYC[msg.sender] = true;
    }

    function getPresaleActive() external view returns(bool){
        return ICOActive[msg.sender];
    }


}