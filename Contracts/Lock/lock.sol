// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./iDatabase.sol";

contract TokenTimelock is Initializable{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    
    iDatabase database;
    
    address public admin;
    address public DEAD;
    // Fee
    uint256 public adminWalletFee; 
    uint256 public stakingPoolFee;
    uint256 public burnFee;
    uint256 public totalfee;

    address adminWalletAddress;
    address stakingPoolAddress;
    address public SSN;
    

    function initialize() external initializer{
        
        database = iDatabase(0x8A6E3213a3351A7F587894f84Fe07C7F86aC7130);
        adminWalletAddress = database.getAdmin();
        stakingPoolAddress = database.getStakingPoolAddress();
        admin = database.getAdmin();

        SSN = database.getTokenAddress();
        DEAD = database.getDEadAddress();
        totalfee = database.getTotalFee();
        burnFee = database.getBurnFee();
        adminWalletFee = database.getAdminWalletFee();

    }
    modifier onlyOwner(){
        
        _;
    }

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
        string Logolink;
        bool Status;
    }
    
    // Locks[] public locks;
    mapping (address => Locks[]) public Owner;

    event LockLog(address token, address user, address beneficiary, uint256 txId, uint256 txTime );
    function lock(
        address token_,
        address beneficiary_,
        uint256 releaseTime_,
        uint256 amount_,
        uint256 period_,
        string memory logoLink_


    ) public {
         
            require (amount_ < IERC20Upgradeable(token_).balanceOf(msg.sender), "Not enough balance");

            uint256 initTime = block.timestamp;
            require(releaseTime_ > initTime, "TokenTimelock: release time is before current time");
            require(amount_ > 0, "You need to lock at least some tokens");

        uint id = database.DatabaseLock(msg.sender, token_, beneficiary_, releaseTime_, amount_, period_, logoLink_);

        emit LockLog(token_, msg.sender, beneficiary_, id, initTime);

    }

    function getTransaction(address owner_, uint256 index)public view returns(IERC20Upgradeable, uint256, address, uint256, uint256, string memory, bool){
        return database.getTransaction(owner_, index);
    }
    function getLockTokens(address token_) public view returns(uint256){
        return _lockTokens[token_];
    }

    function getId(address owner_, uint256 index)public view returns(uint256){
        return database.getId(owner_, index);
    }
  
    function updateWalletAddress() public{
        // require(_newAdminWallet != address(0),"ZA");
        require(msg.sender == admin, "Not Admin");

        adminWalletAddress = database.getAdmin();
        stakingPoolAddress = database.getStakingPoolAddress();
        
    }

    function updateFee()public onlyOwner{
        require(msg.sender == admin, "Not Admin");

        adminWalletFee = database.getAdminWalletFee();
        stakingPoolFee = database.getStakingPoolFee();
        burnFee = database.getBurnFee();
        totalfee = database.getTotalFee();

    }
    // function stakingAddress
    /**
     * @return the token being held.
     */
    function lockLength(address owner_) public view returns (uint){
        return database.lockLength(owner_);
    }

    function token(address owner_, uint index) public view returns (IERC20Upgradeable) {
        return database.token(owner_, index);
    }

    function checkAllowance(IERC20Upgradeable token_, address user) public view returns (uint256){
        return database.checkAllowance(token_, user);
    }

    /**
     * @return the beneficiary of the tokens.
     */

    function beneficiary(address owner_, uint index) public view returns (address) {
        return database.beneficiary(owner_, index);
    }

    /**
     * @return the time when the tokens are released.
     */
     
    function releaseTime(address owner_, uint index) public view returns (uint256) {
        return database.releaseTime(owner_, index);
    }

    function amount(address owner_, uint index) public view returns(uint256){
        return database.amount(owner_, index);
    }


    /**
     * @notice Transfers tokens held by timelock to beneficiary.
    */


    function checkBalance(address owner_) public view returns (uint){
        return database.checkBalance(owner_);
    }


     function release(uint index) public  {
        
        require(Owner[msg.sender][index].Status== false, "Token already released");
        // IERC20Upgradeable e = IERC20Upgradeable(ERC20adr);
        require(block.timestamp >= releaseTime(msg.sender, index), "TokenTimelock: current time is before release time");
        // uint256 bal = checkBalance(msg.sender, index);
        // require (amount(msg.sender, index)<= bal, "Amount must be less than user balance");

        require(amount(msg.sender, index) > 0, "TokenTimelock: no tokens to release");
        
        database.DatabaseRelease(msg.sender, index, address(token(msg.sender, index)), amount(msg.sender, index));


    }

    function changeDatabase(address _newdatabase) external  onlyOwner{
        database = iDatabase(_newdatabase);
    }
}