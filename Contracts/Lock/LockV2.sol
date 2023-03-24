// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";


contract TokenTimeLock{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public admin;
    IERC20Upgradeable public feeToken;
    address public stakingPoolAddress;

    uint256 public stakingPoolFee;
    uint256 public adminWalletFee;
    uint Id;


    uint256[] AllAmountLocked;
    address[] AllTokensLocked;

    mapping(address => address[]) public allTokens;
    mapping(address => uint[]) public allAmount;


    
    struct Locks {
        
        uint id;
        address owner;
        address Token;
        address Beneficiary;
        uint256 amount;
        uint256 releaseTime;
        uint256 dateLocked;
        bool Claimed;
    }

    Locks[] public Alllocked;
    Locks[] public PersonalLocked;
    
    mapping(address => mapping(uint => Locks[])) public LockingDetails;
    // mapping(address => mapping(uint => Locks[])) public LockingDetails2;

    struct inputs{
        address Token;
        address Beneficiary;
        uint256 amount;
        bool Vesting;
        uint256 FirstPercent;
        uint256 firstReleaseTime;
        uint256 cyclePercent;
        uint256 cyclereleaseTime;
        uint256 cycleCount;
    }
    
    
    mapping(address => mapping(uint => mapping (uint => Locks))) public LockedTokens;
    mapping(address => uint) personalLockedCount;
    mapping(address => Locks[]) individualLocks;
    mapping(address => mapping (uint => uint)) cycleCountPerID;
    mapping(address => mapping (uint => uint)) claimCycleCountPerID;
    mapping(address => mapping(uint => uint)) IdtoFinalCount;

    constructor() {
        admin = msg.sender;
        stakingPoolAddress = msg.sender;
    }


    function makeInput(inputs calldata Inputs) internal pure returns(inputs memory){
        inputs memory A = inputs(
            Inputs.Token,
            Inputs.Beneficiary,
            Inputs.amount,
            Inputs.Vesting,
            Inputs.FirstPercent,
            Inputs.firstReleaseTime,
            Inputs.cyclePercent,
            Inputs.cyclereleaseTime,
            Inputs.cycleCount

        );

        return A;
    }


    function Lock(inputs calldata Inputs) external{
        uint count = Inputs.cycleCount; 


        uint totalPrecent = ((count-1) * Inputs.cyclePercent) +Inputs.FirstPercent;

        require(totalPrecent >= 100, "Precentage entered not up to 100%");
 

        personalLockedCount[msg.sender] +=1;

        IERC20Upgradeable(Inputs.Token).safeTransferFrom(msg.sender, address(this), Inputs.amount);
        
        // if(adminWalletFee > 0){
        //     IERC20Upgradeable(feeToken).safeTransferFrom(msg.sender, admin, adminWalletFee);
        // }
        
        // if(stakingPoolFee > 0){
        //     IERC20Upgradeable(feeToken).safeTransferFrom(msg.sender, stakingPoolAddress, stakingPoolFee);
        // }
        

        uint percentAmount = Inputs.amount /100 * Inputs.cyclePercent;

        uint firstAmount = Inputs.amount /100 * Inputs.FirstPercent;

        

        // uint checkAmount = (percentAmount * (count - 1)) + firstAmount;

        // require(checkAmount <= Inputs.amount, "Final Amount Exceeds Sent Amount");

        Id++;



        LockedTokens[msg.sender][Id][1] = Locks ({
            owner : msg.sender,
            id : Id,
            Token :Inputs.Token,
            Beneficiary : Inputs.Beneficiary,
            amount : firstAmount,
            releaseTime: Inputs.firstReleaseTime,
            dateLocked : block.timestamp,
            Claimed : false

        });



        LockingDetails[msg.sender][Id].push(LockedTokens[msg.sender][Id][1]);
        // LockingDetails2[msg.sender][Id ].push(LockedTokens[msg.sender][Id][1]);

        Alllocked.push(LockedTokens[msg.sender][Id][1]);

        uint lastTime = block.timestamp;
        uint maxPrecent = Inputs.FirstPercent;

        if(Inputs.Vesting){
            for(uint i = 2; i <= count; i++){
                
                maxPrecent += Inputs.cyclePercent;

                if(maxPrecent > 100){
                    maxPrecent -= Inputs.cyclePercent;
                    uint percent = 100 - maxPrecent;

                    percentAmount = Inputs.amount /100 * percent;

                }

                lastTime += Inputs.cyclereleaseTime;


                        LockedTokens[msg.sender][Id][i] = Locks ({
                        owner : msg.sender,
                        id : Id,
                        Token :Inputs.Token,
                        Beneficiary : Inputs.Beneficiary,
                        amount : percentAmount,
                        releaseTime: lastTime,
                        dateLocked : block.timestamp,
                        Claimed : false

                    });


                    LockingDetails[msg.sender][Id].push(LockedTokens[msg.sender][Id][i]);

                    // LockingDetails2[msg.sender][Id ].push(LockedTokens[msg.sender][Id][i]);

                    Alllocked.push(LockedTokens[msg.sender][Id][i]);

                }

                

        }


        cycleCountPerID[msg.sender][Id] = count;
        
        allTokens[msg.sender].push(Inputs.Token);
        allAmount[msg.sender].push(Inputs.amount);

        AllAmountLocked.push(Inputs.amount);
        AllTokensLocked.push(Inputs.Token);


        PersonalLocked.push(Locks ({
            owner : msg.sender,
            id : Id,
            Token :Inputs.Token,
            Beneficiary : Inputs.Beneficiary,
            amount : Inputs.amount,
            releaseTime: lastTime,
            dateLocked : block.timestamp,
            Claimed : false

                }));     

        individualLocks[msg.sender].push(Locks ({
            owner : msg.sender,
            id : Id,
            Token :Inputs.Token,
            Beneficiary : Inputs.Beneficiary,
            amount : Inputs.amount,
            releaseTime: lastTime,
            dateLocked : block.timestamp,
            Claimed : false

                }));     




    }



    function Release(uint id) external{

        uint claimCount = claimCycleCountPerID[msg.sender][id] + 1;

        require(claimCycleCountPerID[msg.sender][id] < cycleCountPerID[msg.sender][id], "Fully Claimed Already");

        require(block.timestamp > LockedTokens[msg.sender][id][claimCount].releaseTime, "Time not reached for release");

        require(!LockedTokens[msg.sender][id][claimCount].Claimed, "Already Claimed for the index");


        address _token = LockedTokens[msg.sender][id][claimCount].Token;
        address _beneficiary = LockedTokens[msg.sender][id][claimCount].Beneficiary;

    
        
        uint claimmableAmount;

        for(uint i = claimCount; i <= cycleCountPerID[msg.sender][id]; i++){

            if(block.timestamp > LockedTokens[msg.sender][id][i].releaseTime){

                claimmableAmount += LockedTokens[msg.sender][id][i].amount;

                LockedTokens[msg.sender][id][i].Claimed = true;

                claimCycleCountPerID[msg.sender][id] ++;

            } else{
                break;
            }
        }
    
         
        IERC20Upgradeable(_token).safeTransfer(_beneficiary, claimmableAmount);
        


    }


    
    function getTransaction(address owner_, uint id, uint256 index) external view returns(Locks memory){
        return LockedTokens[owner_][id][index];
    }

    function getVestingDetailsForLock(address owner, uint id) external view returns(Locks[] memory){
        return LockingDetails[owner][id];
    }


    function getUserLocks(address owner) external view returns(Locks[] memory){
        return individualLocks[owner];
    }
    function getEachLock() external view returns(Locks[] memory){
        return PersonalLocked;
    }

    // function getLockedTokenDetailsWithIndex(address owner, uint id) external view returns(Locks[] memory){
    //     return LockingDetails2[owner][id];
    // }

  function getAllLockedDetailsInContract() external view returns(Locks[] memory){
      return Alllocked;
  }


    function updateWalletAddress(address _newAdminWallet, address _newStakingWallet) external{
        require(msg.sender == admin, "Not Admin");
        admin = _newAdminWallet;
        stakingPoolAddress = _newStakingWallet;
    }

    function updateFee(uint256 adminWalletFee_, uint256 stakingPoolFee_) external {
        require(msg.sender == admin, "Not Admin");
        adminWalletFee = adminWalletFee_;
        stakingPoolFee = stakingPoolFee_;

    }
    
    function token(address owner_, uint id, uint index) external view returns (address) {
        return LockedTokens[owner_][id][index].Token;
    }

    function beneficiary(address owner_, uint id, uint index) external view returns (address) {
        return LockedTokens[owner_][id][index].Beneficiary;
    }

    function releaseTime(address owner_, uint id, uint index) external view returns (uint256) {
        return LockedTokens[owner_][id][index].releaseTime;
    }

    function amount(address owner_, uint id, uint index) external view returns(uint256){
        return LockedTokens[owner_][id][index].amount;
    }

    function getClaimed(address owner_, uint id, uint index) external view returns(bool){
        return LockedTokens[owner_][id][index].Claimed;
    }
    function getAllTokensAndAmountForUser(address user) external view returns(address[] memory, uint256[] memory){
        return (allTokens[user], allAmount[user]);

    }
    function getAllTokensAndAmountInContract() external view returns(address[] memory, uint256[] memory){
        return (AllTokensLocked, AllAmountLocked);

    }


}
