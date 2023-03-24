//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./BasicStructs.sol";
import "./Idatabase.sol";
import "./IPancakePair.sol";
import "./IPancakeFactory.sol";
import "./IPancakeRouter.sol";



interface IFactory{
    function updateAsSaleEnded(address _ico) external;
}

interface motherPool {
    function receiveTokenFee(address _token, uint256 amount) external;
}

interface ILock{
    function launchLock(
        address owner, 
        address token_,   
        address beneficiary_,
        uint256 releaseTime_,
        uint256 amount_
    ) external;
}

contract ICO is Initializable{

    // ICO attributes here
    ICOparam public icoInfo;
    IERC20Upgradeable public token;
    Idatabase public dataStorage;
    

    // ENS Burn address
    address public DEAD;
    bool public isKYC;
    bool public isAudit;


    mapping(address => bool) public whitelisted;
    address[] public _whitelist;
    bool public isWhiteListed;
    uint256 public wlLastDate;
    uint256 public totalWhitelisted;
    uint tokenRemainderBeforeBurn;
    
    
    uint256 public raisedBNB;
    uint256 public soldToken;
    uint256 public bnbToLiquidity;
    
    bool public isCanceled;
    bool public isFinalized;

    
    mapping(address => uint256) public purchase;
    mapping(address => uint256) public spentBNB;

    // Some Events
    event Purchase(address indexed _account, uint256 _value,uint256 _id);

    // Pancake info
    address public pancakeRouterAddress;
    IPancakeRouter02 public pancakeSwapRouter;
    address public pancakeSwapPair;



     //Vesting
    
    struct VestingPriod{
        uint percent;
        uint startTime;
        uint vestingCount;
       uint MaxClaim;
    }

    vestingStruct public vesting;
    
    uint public maxPercent;
    bool public Vesting;
    uint public VestingCount;

    VestingPriod public _vestingPeriod;

    mapping(uint => VestingPriod) public PeriodtoPercent;
    mapping(address => uint) public TotalBalance;
    mapping(address => uint) private claimCount;
    mapping(address => uint) private claimedAmount;
    mapping(address => uint) private claimmable;


    
    function initialize (ICOparam memory _data, vestingStruct memory _struct) external initializer{
        icoInfo = _data;
        isWhiteListed = icoInfo.data.whiteListEnabled;
        wlLastDate = icoInfo.data.whitelistLastDate;
        Vesting = icoInfo.data.Vesting;
        DEAD = 0x000000000000000000000000000000000000dEaD;
        pancakeRouterAddress = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
        token = IERC20Upgradeable(icoInfo.data.tokenAddress);
        dataStorage = Idatabase(0xDdA2f34BE0Cefd1AeF7FEF253767aD74Cd93Ec02);
        vesting = _struct;
        IPancakeRouter02 _uniswapV2Router = IPancakeRouter02(pancakeRouterAddress);
        pancakeSwapRouter = _uniswapV2Router;
        pancakeSwapPair = IPancakeFactory(_uniswapV2Router.factory()).getPair(icoInfo.data.tokenAddress, _uniswapV2Router.WETH());
     
       if(pancakeSwapPair == address(0)){

            pancakeSwapPair = IPancakeFactory(_uniswapV2Router.factory()).createPair(icoInfo.data.tokenAddress, _uniswapV2Router.WETH());
        }
        
         
        
    }

    function setPairAddress() external{
        // require(msg.sender == icoInfo.factory,"NF");//Not Factory
        IPancakeRouter02 _uniswapV2Router = IPancakeRouter02(pancakeRouterAddress);
        address _uniswapV2Pair = IPancakeFactory(0x6725F303b657a9451d8BA641348b6761A6CC7a17).createPair(icoInfo.data.tokenAddress, _uniswapV2Router.WETH());
        pancakeSwapPair = _uniswapV2Pair;
        pancakeSwapRouter = _uniswapV2Router;
    }

    function setIsKYCAndAudit(bool kyc,bool audit) external{
    require(msg.sender == address(dataStorage));
        isKYC = kyc;
        isAudit = audit;
    }

    
    function _requestKYCandAudit() external {
        require(msg.sender == icoInfo.owner,"NO");//Not Owner

        dataStorage.requestKYCandAudit();

    }

    

    receive() external payable{
        buyTokens();
    }
    


    function getUsersPurchase(address _user) external view returns(uint256){
        return purchase[_user];
    }


    function getContribution(address _user) external view returns(uint256){
        return spentBNB[_user];
    }

    function getReceivableToken(address _user) external view returns(uint256){
        return purchase[_user];
    }
    
    function getPresaleSupply() external view returns(uint){
        return icoInfo.data.presaleSupply;
    }

    function getBalance() external view returns(uint){
        
        uint256 bal = token.balanceOf(address(this));

        return bal;
    }
    function getLiquiditySupply() external view returns(uint){

        return bnbToLiquidity;
    }
    function getLocekdtokens() external view returns(uint){
        if(isFinalized){
            uint256 _amount = IERC20Upgradeable(pancakeSwapPair).balanceOf(address(this));
            return _amount;
        } else {
            return 0;
        }
    }
    function getUnlockedTokens() external view returns(uint){
        if(isFinalized || isCanceled){
            return 0;
        }else{
            return token.balanceOf(address(this));
        }
        
    }
    function getBurntTokens() external view returns(uint){
        if(isFinalized && icoInfo.data.burnRemaining){
            return tokenRemainderBeforeBurn;
        }else{
            return 0;
        }
    }








    function buyTokens() public payable{
        require(icoInfo.data.presaleStartTime <= block.timestamp, "NS");//Not Started
        require(icoInfo.data.presaleEndTime > block.timestamp,"AE");//Already Ended
        require(raisedBNB < icoInfo.data.hardCap, "HR");//Hardcap Reached
        require(dataStorage.getPresaleActive(), "PNA");//Presael not Active
        require(msg.value + raisedBNB <= icoInfo.data.hardCap, "GOHC");//Going over hard cap 
        require(msg.value + spentBNB[msg.sender]>= icoInfo.data.minAmount,"MANR");//Minimum amount not reached
        require(msg.value + spentBNB[msg.sender] <= icoInfo.data.maxAmount,"MLR");//Maximum limit reached

        bool canBuy;

        if(isWhiteListed){
            if(whitelisted[msg.sender]){
                canBuy = true;
            }else{
                canBuy = false;
            }
        }else{
            canBuy = true;
        }

        require(canBuy,"CB");//Cannot buy

        
        uint256 totalReceivable = icoInfo.data.ratePerBNB * msg.value;

        
        spentBNB[msg.sender] += msg.value;
        purchase[msg.sender] += totalReceivable;
     

        raisedBNB +=msg.value;

        soldToken += totalReceivable;

         TotalBalance[msg.sender] += totalReceivable;

        emit Purchase(msg.sender, totalReceivable,icoInfo.id);
        
    }

    
    function emergencyWithdraw(uint256 amount_) external {
        require(icoInfo.data.presaleEndTime > block.timestamp,"PE");//Presale Ended
        require(!isCanceled,"PC");//Presale Cancelled
        require(spentBNB[msg.sender] >= amount_,"IA");//Insufficient Amount 

        uint256 fees = amount_ * 10 / 100;
        uint256 receivable = amount_ - fees;

        raisedBNB -= amount_;
        purchase[msg.sender] -= (amount_ * icoInfo.data.ratePerBNB);
        spentBNB[msg.sender] -= amount_;

        payable(msg.sender).transfer(receivable);
        payable(icoInfo.fees.AdminWalletAddress).transfer(fees);

    }

    

    function cancelPresale() external{
        require(icoInfo.data.presaleEndTime > block.timestamp,"PE");//Presale Ended
        require(msg.sender == icoInfo.owner,"NO");//Not Owner
        require(!isCanceled,"PC");//Presale Cancelled

        _cancelPresale();
    }

    
    function _cancelPresale() internal{

        uint256 balance = token.balanceOf(address(this));

        token.transfer(icoInfo.owner, balance);

        isCanceled = true;

    }

    function adminCancelPresale() external{
        require(msg.sender == icoInfo.factory,"NF");//Not Factory
        require(!isCanceled,"PC");//Presale Cancelled
        
        _cancelPresale();

    }

    
    function claimRefund() external{    
        require(!isFinalized,"AF");//Already FInalised
        require(isCanceled,"PNC");//Prsale Not cancelled
        require(spentBNB[msg.sender] > 0, "UB");//Unavailable Balance
        
        uint refund = spentBNB[msg.sender];

        delete purchase[msg.sender];
        delete spentBNB[msg.sender];

        payable(msg.sender).transfer(refund);
    }

    
    function endSale() external{
        require(msg.sender == icoInfo.owner,"NO");//Not Owner
        require(!isCanceled,"PC");
        require(icoInfo.data.presaleEndTime < block.timestamp,"NE");


        if(raisedBNB < icoInfo.data.softCap){
            _cancelPresale();
        }else{
            
            isFinalized = true;
        
            _distribute();

            if(icoInfo.data.lockLiquidity){
                
                uint256 tokenAmount = IERC20Upgradeable(pancakeSwapPair).balanceOf(dataStorage.getLockAddress());

                _lockLPTokens(tokenAmount, icoInfo.owner,icoInfo.data.liquidityLockTime);

            }
         
        uint256 adminToken = icoInfo.data.presaleSupply * icoInfo.fees.feesTokenAdmin / 10000;
      
        uint256 stakeToken = icoInfo.data.presaleSupply * icoInfo.fees.feesTokenStaking / 10000;
        
            token.transfer(icoInfo.fees.AdminWalletAddress, adminToken);

            token.transfer(icoInfo.fees.StakingWalletAddress, stakeToken);
            // motherPool(icoInfo.fees.StakingWalletAddress).receiveTokenFee(address(token), stakeToken);
            
            remainingTokens();
        }

      //  dataStorage.endPresale();

    }

    
    function _distribute() internal {
    
        uint256 fees = icoInfo.fees.feesBNB * address(this).balance / 10000;

        bnbToLiquidity = icoInfo.data.liquiditySupply * raisedBNB / 10000;
        
        uint256 ownerscut = raisedBNB - bnbToLiquidity;

        payable(icoInfo.owner).transfer(ownerscut);
        
         _provideLiquidity(bnbToLiquidity - fees);

        payable(icoInfo.fees.AdminWalletAddress).transfer(fees);

    }
        
    function remainingTokens() internal {

        uint claimmableToken = raisedBNB * icoInfo.data.ratePerBNB;

          uint256 bal = token.balanceOf(address(this)) - claimmableToken;

          tokenRemainderBeforeBurn = bal;

        if(bal > 0){
            if(icoInfo.data.burnRemaining){
                token.transfer(DEAD,bal);
            }else {
                    token.transfer(icoInfo.owner,bal);
                }
            }

    }
    
    function _provideLiquidity(uint256 bnbAmount) internal {
        
        uint256 tokenAmount = icoInfo.data.exchangeListingRateBNB * bnbAmount;
        
        token.approve(pancakeRouterAddress, tokenAmount);
        token.approve(pancakeSwapPair, tokenAmount);


        address locker = dataStorage.getLockAddress();


        // add the liquidity
        pancakeSwapRouter.addLiquidityETH{value: bnbAmount}(
            icoInfo.data.tokenAddress,
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            locker, // Liquidity Locker or Creator Wallet
            block.timestamp + 360
        );
    }

    
    function _lockLPTokens(uint256 _amount,address _owner,uint256 _liquidityLockTime) internal{ 
        
        ILock locker = ILock(dataStorage.getLockAddress());
        
        token.approve(address(locker), _amount);

        locker.launchLock(msg.sender, icoInfo.data.tokenAddress, _owner , _liquidityLockTime + block.timestamp, _amount);
        
    }

    function Claim() external{
        if(Vesting){
            _vestingClaim();
        }else {
            _normalClaim();
        }
    }

    function _normalClaim() internal {
        require(icoInfo.data.presaleEndTime < block.timestamp,"PNE");//Presale Not ended
        require(!isCanceled,"PC");//Presale Cancelled 
        require(isFinalized,"PNF");//Pressale not finalised
        
        uint bal = purchase[msg.sender];

        delete purchase[msg.sender];
        delete spentBNB[msg.sender];
        
        token.transfer(msg.sender, bal);
    }

    
    //Vesting 
 

    function updateVesting(bool newStatus) external {
        require(msg.sender == icoInfo.owner,"NO");//Not Owner
        require(Vesting != newStatus);

        Vesting = newStatus;
    }

    uint[] public time;
    uint[] public percent;

    function getVesting() external view returns(uint[] memory, uint[] memory){
        return(time, percent);
    }

    function setVesting() external {
        

        uint count = vesting.cycleCount; 


        uint totalPrecent = ((count-1) * vesting.cyclePercent) +vesting.firstPercent;

        require(totalPrecent >= 10000, "Precentage entered not up to 100%");


           VestingCount++;
           maxPercent += vesting.firstPercent;

           PeriodtoPercent[VestingCount] = VestingPriod({
            percent : vesting.firstPercent,
            startTime : vesting.firstReleaseTime,
            vestingCount : VestingCount,
            MaxClaim : maxPercent
        });

        vestingDetails.push(PeriodtoPercent[VestingCount]);

        time.push(vesting.firstReleaseTime);
        percent.push(vesting.firstPercent);

        uint lastime = vesting.firstReleaseTime;
        uint percentAmount;

        

            for(uint i = 2; i<= vesting.cycleCount; i++){
            
            lastime += vesting.cycleReleaseTime;
            
            require(lastime > PeriodtoPercent[VestingCount-1].startTime);
            
            maxPercent += vesting.cyclePercent;
            percentAmount = vesting.cyclePercent;

                if(maxPercent > 10000){

                    maxPercent -= vesting.cyclePercent;
                    percentAmount = 10000 - maxPercent;  

                    maxPercent += percentAmount; 

                }
            
            time.push(lastime);
            percent.push(percentAmount);

            VestingCount++;

            PeriodtoPercent[VestingCount] = VestingPriod({

                        percent : percentAmount,
                        startTime : lastime,
                        vestingCount : VestingCount,
                        MaxClaim : maxPercent
                    });
                    vestingDetails.push(PeriodtoPercent[VestingCount]);
            }

        
    }
    mapping(address => mapping(uint => bool)) public vestingToClaimed;
    mapping(address => mapping(uint => uint)) public recievedTokens;
    VestingPriod[] vestingDetails;

    function getVestingDetailes() external view returns(VestingPriod[] memory){
        return vestingDetails;
    }

    

  
    function _vestingClaim() internal {
        require(Vesting, "VNS");//Vesting Not set
        require(isFinalized, "NF");//Not finalised
        require(claimCount[msg.sender] <= VestingCount,"CC");//Claiming Complete
        

        for(uint i = claimCount[msg.sender]; i<= VestingCount; i++){
            if(PeriodtoPercent[i].startTime <= block.timestamp){
                claimmable[msg.sender] +=PeriodtoPercent[i].percent;
                claimCount[msg.sender] ++;
                vestingToClaimed[msg.sender][i] = true;
            }
            else 
            break;
        }
        
            
        require(claimmable[msg.sender] <= 10000);
        
        recievedTokens[msg.sender][claimCount[msg.sender]] = claimmable[msg.sender];
        uint _amount = claimmable[msg.sender] /10000* TotalBalance[msg.sender];

        purchase[msg.sender] -= _amount;
        claimedAmount[msg.sender] += claimmable[msg.sender]; 
  
        delete claimmable[msg.sender];
        delete spentBNB[msg.sender];

        token.transfer(msg.sender, _amount);

    }

    function getDistributedTokens(address user) external view returns(uint[] memory){
         uint256[] memory array = new uint256[](claimCount[user]);
            for (uint i=0; i<claimCount[user]; i++) {
                array[i] = recievedTokens[user][i];
            }
        return array;
    }






    //Whitelist


    
    function retriveWhiteList()external view returns(address[] memory){
        return _whitelist;
    }

    function isUserWhitelisted(address _user) external view returns(bool){
        return whitelisted[_user];
    }


    function addToWhiteList(address[] memory users) external{
        require(msg.sender == icoInfo.owner,"NO");//Not Owner

        for(uint256 i = 0 ; i < users.length; i++){
            whitelisted[users[i]] = true;
            _whitelist.push(users[i]);
            totalWhitelisted++;
        }
    }



    function removeToWhiteList(address[] memory users) external{
        require(msg.sender == icoInfo.owner,"NO");//Not Owner

        for(uint256 i=0 ; i<users.length;i++){
            whitelisted[users[i]] = false;
            totalWhitelisted++;
        }
    }


    function checkWhiteList() external view returns(bool){
        return isWhiteListed;
    }

    function updateWhitelistStatus(bool newStatus) external {
        require(msg.sender == icoInfo.owner,"NO");//Not Owner
        require(isWhiteListed != newStatus,"ASTS");//Already set to status 

        isWhiteListed = newStatus;
    }

    function changeDatabase(address newDatabase) external{
        require(dataStorage.getAdmin() == msg.sender);

        dataStorage = Idatabase(newDatabase);
    }


    function returnMoney() external{
        payable(msg.sender).transfer(address(this).balance);
    }


}