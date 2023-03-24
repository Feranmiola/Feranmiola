// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./iDatabase.sol";

contract Database is Initializable{

     using SafeERC20Upgradeable for IERC20Upgradeable;
    
    address public ERC20adr;
    IERC20Upgradeable _token;
    // beneficiary of tokens after they are released
    address public _beneficiary;
    uint256 id;

    function setAdr(address ERC20adr_) external{
        ERC20adr = ERC20adr_;
    }
    
    address public DEAD;
    // Fee
    uint256 public adminWalletFee; 
    uint256 public stakingPoolFee;
    uint256 public burnFee;
    uint256 public totalfee;

    address admin;
    address stakingPoolAddress;
    address public SSN;
    address launchAddress;

    address lockCaller;
    address lpLockCaller;

    mapping (address => uint256) _lockTokens;
    mapping (address => Locks[]) public Owner;
    

    struct Locks {
        // ERC20 basic token contract being held
        IERC20Upgradeable Token;
        
        uint256 Id;
        address Beneficiary;
        // timestamp when token release is enabled
        uint256 ReleaseTime;
        //amount to be locked
        uint256 Amount;
        string LogoLink;
        bool Status;
    }
    
    

    function initialize(address _stakingAddress) external{
            // update fees addresses
        admin = msg.sender;
        stakingPoolAddress = _stakingAddress;
        

        SSN = 0x8A6E3213a3351A7F587894f84Fe07C7F86aC7130;
        DEAD = 0x000000000000000000000000000000000000dEaD;
        totalfee = adminWalletFee +stakingPoolFee+burnFee;
        burnFee = 100 * 10**9;
        adminWalletFee = 0.00696 * 10**9;
        

    }

    //Getter Functions

    function getAdmin() external view returns(address){
        return admin;
    }

    function getStakingPoolAddress() external view returns(address){
        return stakingPoolAddress;
    }

    function getTokenAddress() external view returns(address){
        return SSN;
    }
    function getDEadAddress() external view returns(address){
        return DEAD;
    }
    function getERC20adr() external view returns(address){
        return ERC20adr;
    }
    function get_token() external view returns(IERC20Upgradeable){
        return _token;
    }
    function getBeneficiary() external view returns(address){
        return _beneficiary;
    }
    
    function getAdminWalletFee() external view returns(uint){
        return adminWalletFee;
    }
    function getStakingPoolFee() external view returns(uint){
        return stakingPoolFee;
    }
    function getBurnFee() external view returns(uint){
        return burnFee;
    }
    function getTotalFee() external view returns(uint){
        return totalfee;
    }


    function getLockTokens(address token_) external view returns(uint256){
        return _lockTokens[token_];
    }
    function getTransaction(address owner_, uint256 index)external view returns(IERC20Upgradeable, uint256, address, uint256, uint256, string memory, bool){
        return (
                Owner[owner_][index].Token,
                Owner[owner_][index].Id,
                Owner[owner_][index].Beneficiary,
                Owner[owner_][index].ReleaseTime,
                Owner[owner_][index].Amount,
                Owner[owner_][index].LogoLink,
                Owner[owner_][index].Status
                );
    }

    function getId(address owner_, uint256 index)external view returns(uint256){
        return Owner[owner_][index].Id;
    }

    function lpApprove( IERC20Upgradeable tkAdr, address spender, uint256 value) external  {
        tkAdr.safeApprove(spender, value);
    }
   
    function checkBalance(address owner_ ) external view returns (uint){
        IERC20Upgradeable e = IERC20Upgradeable(ERC20adr);
        return e.balanceOf(owner_);
    }

     function lockLength(address owner_) external view returns (uint){
        return Owner[owner_].length;
    }

    function token(address owner_, uint index) external view returns (IERC20Upgradeable) {
        return Owner[owner_][index].Token;
    }

    function checkAllowance(IERC20Upgradeable token_, address user) external view returns (uint256){
        return token_.allowance(user, address(this));
    }

    function beneficiary(address owner_, uint index) external view returns (address) {
        return Owner[owner_][index].Beneficiary;
    }
     
    function releaseTime(address owner_, uint index) external view returns (uint256) {
        return Owner[owner_][index].ReleaseTime;
    }

    function amount(address owner_, uint index) external view returns(uint256){
        return Owner[owner_][index].Amount;
    }
    function checkBalance(IERC20Upgradeable token_, address owner_) external view returns (uint){
        return token_.balanceOf(owner_);
    }
    function getStatus(address sender, uint index) external view returns(bool){
        return Owner[sender][index].Status;
    }
    





function DatabaseLock( address sender, address token_, address beneficiary_, uint256 releaseTime_, uint256 amount_, uint256 period_, string memory logoLink_) external returns(uint){

    if(msg.sender == lpLockCaller){

        address _owner = beneficiary_;
            require (amount_ < IERC20Upgradeable(token_).balanceOf(sender), "Not enough balance");
            uint256 initTime = block.timestamp;
            require(releaseTime_ > initTime, "TokenTimelock: release time is before current time");
            Locks memory locks = Locks(IERC20Upgradeable(token_), id++, beneficiary_, releaseTime_, amount_, logoLink_, false);
            Owner[_owner].push(locks);    
        
            IERC20Upgradeable(token_).transferFrom(sender, address(this), amount_);

            // payable(sender).transfer(amount_);
            // IERC20Upgradeable(token_).transfer(address(this), amount_);

            IERC20Upgradeable(SSN).transferFrom(sender, admin, adminWalletFee);
            IERC20Upgradeable(SSN).transferFrom(sender, DEAD, burnFee);
            if(stakingPoolFee!= 0){
                IERC20Upgradeable(SSN).transferFrom(sender, stakingPoolAddress, stakingPoolFee);
            }
            // emit LockLog(token_, sender, beneficiary_, id, initTime);

            _lockTokens[token_] += amount_;

            return id;

        }else {
            if(msg.sender == lockCaller){
                   
            uint256 initTime = block.timestamp;

            if(period_>1){

                uint256 partTime= (releaseTime_ - block.timestamp)/period_;
                uint256 partAmount = amount_/period_;
                
                for(uint i=1; i<=period_; i++){
                // Vest storage newVest = Vest(_amount/_period, block.timestamp+i*partTime);
                // Owner[_owner].push(locks(token, beneficiary_, block.timestamp+i*partTime, partAmount ));
                Locks memory locks = Locks(IERC20Upgradeable(token_), id, beneficiary_, initTime+i*partTime, partAmount, logoLink_, false);
                Owner[beneficiary_].push(locks);
                }
            }
            else{
            Locks memory locks = Locks(IERC20Upgradeable(token_), id, beneficiary_, releaseTime_, amount_, logoLink_, false);
                Owner[beneficiary_].push(locks);        
            }
            

            IERC20Upgradeable(token_).transferFrom(sender, address(this), amount_);


                IERC20Upgradeable(SSN).transferFrom(sender, admin, adminWalletFee);
                IERC20Upgradeable(SSN).transferFrom(sender, DEAD, burnFee);
                if(stakingPoolFee!= 0){
                    IERC20Upgradeable(SSN).transferFrom(sender, stakingPoolAddress, stakingPoolFee);
                }
            
            id++;
            _lockTokens[token_] += amount_;

            return id;
            }
                else{
                revert("Unknown Caller");
            }
        }

    }

    function DatabaseLaunchLock(address sender, address token_, address beneficiary_, uint256 releaseTime_, uint256 amount_, string memory logoLink_) external returns(uint){
        if(msg.sender == lpLockCaller){
            
        Locks memory locks = Locks(IERC20Upgradeable(token_), id++, beneficiary_, releaseTime_, amount_, logoLink_, false);
        Owner[beneficiary_].push(locks);  
        IERC20Upgradeable(token_).transferFrom(sender, address(this), amount_);
        
        _lockTokens[token_] += amount_;

        return id;

        }else{
            revert("Unknown Caller");
        }
    }

    function DatabaseRelease(address sender, uint index, address tokentoLock, uint _amount) external{
        if(msg.sender == lpLockCaller || msg.sender == lockCaller){
        
        IERC20Upgradeable(Owner[sender][index].Token).transfer(Owner[sender][index].Beneficiary, _amount);

        Owner[sender][index].Status = true;
        _lockTokens[tokentoLock] -= _amount;

        }else{
            revert("Unknown Caller");
        }
    }



    function updateWalletAddress(address _newAdminWallet, address _newStakingWallet, address _newLaunchAddress) external{
        require(msg.sender == admin, "Not Admin");

        admin = _newAdminWallet;
        stakingPoolAddress = _newStakingWallet;
        launchAddress = _newLaunchAddress;
    }
    function updateFee(uint256 adminWalletFee_, uint256 stakingPoolFee_, uint256 burnFee_ )external {
        require(msg.sender == admin, "Not Admin");

        adminWalletFee = adminWalletFee_;
        stakingPoolFee = stakingPoolFee_;
        burnFee = burnFee_;
        totalfee = adminWalletFee + stakingPoolFee + burnFee;
    }




}