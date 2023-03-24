// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";


contract LPTimelock {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address public ERC20adr;
    IERC20Upgradeable _token;
    // beneficiary of tokens after they are released
    address public _beneficiary;
    uint256 id;

    function setAdr(address ERC20adr_) external{
        ERC20adr = ERC20adr_;
    }
    address OWNER;
    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    // Fee
    uint256 public adminWalletFee = 0.00696 * 10**9; 
    uint256 public stakingPoolFee = 0;
    uint256 public burnFee = 100 * 10**9;
    uint256 public totalfee = adminWalletFee +stakingPoolFee+burnFee;

    address adminWalletAddress = address(0);
    address stakingPoolAddress = address(0);
    address immutable public SSN = 0x8A6E3213a3351A7F587894f84Fe07C7F86aC7130;
    address launchAddress = address(0);

    constructor(address _adminAddress,address _stakingAddress){
        // update fees addresses
        adminWalletAddress = _adminAddress;
        stakingPoolAddress = _stakingAddress;
        OWNER = msg.sender;
    }
    modifier onlyOwner(){
        require(msg.sender==OWNER,"Not Allowed");
        _;
    }
    //  modifier onlyLaunch(){
    //     require(msg.sender==launchAddress,"Not launch");
    //     _;
    // }
    mapping (address => uint256) _lockTokens;

    struct Locks {
        // ERC20 basic token contract being held
        IERC20Upgradeable Token;
        
        uint256 Id;
        address Beneficiary;
        // timestamp when token release is enabled
        uint256 ReleaseTime;
        //amount to be locked
        uint256 Amount;
        bool Status;
    }
    // Locks[] public locks;
    mapping (address => Locks[]) public Owner;
    event LockLog(address token, address user, address beneficiary, uint256 txId, uint256 txTime );

    function lock(
        address token_,
        address beneficiary_,
        uint256 releaseTime_,
        uint256 amount_

    ) external {
        address _owner = beneficiary_;
        require (amount_ < IERC20Upgradeable(token_).balanceOf(msg.sender), "Not enough balance");
        uint256 initTime = block.timestamp;
        require(releaseTime_ > initTime, "TokenTimelock: release time is before current time");
        Locks memory locks = Locks(IERC20Upgradeable(token_), id++, beneficiary_, releaseTime_, amount_, false);
        Owner[_owner].push(locks);    
         // IERC20Upgradeable(token_).approve(address(this),  amount_);
         require(amount_ > 0, "You need to lock at least some tokens");
        // IERC20Upgradeable(token_).approve(address(this), amount_);
        uint256 allowance = IERC20Upgradeable(token_).allowance(msg.sender, address(this));

        require(allowance >= amount_, "Check the token allowance");

        IERC20Upgradeable(token_).transferFrom(msg.sender, address(this), amount_);

        // payable(msg.sender).transfer(amount_);
        // IERC20Upgradeable(token_).transfer(address(this), amount_);

        IERC20Upgradeable(SSN).transferFrom(msg.sender, adminWalletAddress, adminWalletFee);
        IERC20Upgradeable(SSN).transferFrom(msg.sender, DEAD, burnFee);
        if(stakingPoolFee!= 0){
            IERC20Upgradeable(SSN).transferFrom(msg.sender, stakingPoolAddress, stakingPoolFee);
        }
        emit LockLog(token_, msg.sender, beneficiary_, id, initTime);

        _lockTokens[token_] += amount_;

}


function launchLock(
    address owner, 
    address token_,   
    address beneficiary_,
    uint256 releaseTime_,
    uint256 amount_
    ) external {
    address _owner = beneficiary_;

    uint256 initTime = block.timestamp;
    

    Locks memory locks = Locks(IERC20Upgradeable(token_), id++, beneficiary_, releaseTime_, amount_, false);
    
    Owner[_owner].push(locks);  
    
    IERC20Upgradeable(token_).transferFrom(msg.sender, address(this), amount_);

    emit LockLog(token_, owner, beneficiary_, id, initTime);

    _lockTokens[token_] += amount_;
    
    }

function getLockTokens(address token_) public view returns(uint256){
        return _lockTokens[token_];
    }
    function getTransaction(address owner_, uint256 index)public view returns(Locks memory){
        return Owner[owner_][index];
    }

    function getId(address owner_, uint256 index)public view returns(uint256){
        return Owner[owner_][index].Id;
    }

    
    function updateWalletAddress(address _newAdminWallet, address _newStakingWallet, address _newLaunchAddress) public onlyOwner virtual{
        // require(_newAdminWallet != address(0),"ZA");
        adminWalletAddress = _newAdminWallet;
        stakingPoolAddress = _newStakingWallet;
        launchAddress = _newLaunchAddress;
    }

    function updateFee(uint256 adminWalletFee_, uint256 stakingPoolFee_, uint256 burnFee_ )public onlyOwner{
    adminWalletFee = adminWalletFee_;
    stakingPoolFee = stakingPoolFee_;
    burnFee = burnFee_;
    totalfee = adminWalletFee + stakingPoolFee + burnFee;
    }


    /**
     * @dev return the token being held.
     */
    function lockLength(address owner_) public view returns (uint){
        return Owner[owner_].length;
    }
    function lpApprove( IERC20Upgradeable tkAdr, address spender, uint256 value) public  {
        tkAdr.safeApprove(spender, value);
    }

    function token(address owner_, uint index) public view returns (IERC20Upgradeable) {
        return Owner[owner_][index].Token;
    }


    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary(address owner_, uint index) public view returns (address) {
        return Owner[owner_][index].Beneficiary;
    }

    /**
     * @return the time when the tokens are released.
     */
    function releaseTime(address owner_, uint index) public view returns (uint256) {
        return Owner[owner_][index].ReleaseTime;
    }

    function amount(address owner_, uint index) public view returns(uint256){
        return Owner[owner_][index].Amount;
    }
   

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
    */
    

    // function release_vest(uint256 index, uint256 id) public {
    //     require(block.timestamp>=Owner[_owner][index].vest[id].vest_time, "TokenTimelock: current time is before release time");
    //     require(Owner[_owner][index].vest[id].vest_amount > 0, "TokenTimelock: no tokens to release");

    //     IERC20Upgradeable(token()).safeTransfer(beneficiary(), Owner[_owner][index].vest[id].vest_amount);

    // }
    function checkBalance(address owner_ ) public view returns (uint){
        IERC20Upgradeable e = IERC20Upgradeable(ERC20adr);
        return e.balanceOf(owner_);
    }

     function release(uint index) public  {
        // IERC20Upgradeable e = IERC20Upgradeable(ERC20adr);
        require(Owner[msg.sender][index].Status== false, "Token already released");

        require(block.timestamp >= releaseTime(msg.sender, index), "TokenTimelock: current time is before release time");
        // uint256 bal = checkBalance(msg.sender, index);
        // require (amount(msg.sender, index)<= bal, "Amount must be less than user balance");
        require(amount(msg.sender, index) > 0, "TokenTimelock: no tokens to release");

        Owner[msg.sender][index].Status = true;

        token(msg.sender, index).transfer(beneficiary(msg.sender, index), amount(msg.sender, index));


        _lockTokens[address(token(msg.sender, index))] -= amount(msg.sender, index);


    }
}
