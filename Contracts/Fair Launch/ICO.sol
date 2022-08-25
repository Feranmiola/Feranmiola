// SPDX-License-Identifier: UNLICENCED
pragma solidity >=0.8.10;

import "./IPancakeRouter.sol";
import "./IPancakeFactory.sol";
import "./IPancakePair.sol";
import "./IERC20.sol";
import './SafeMath.sol';
import "./BasicStructs.sol";

interface IFactory{
    function updateAsSaleEnded(address _ico) external;
}
interface ILock{
    function lock(
        address token_,
        address beneficiary_,
        uint256 releaseTime_,
        uint256 amount_

    ) external;
}

contract ICO{
    using SafeMath for uint256;

    // ICO attributes here
    ICOparam public icoInfo;

    // ENS Burn address
    address immutable public DEAD = 0x000000000000000000000000000000000000dEaD;
    bool public isKYC;
    bool public isAudit;
    uint256 wlLastDate;
    uint256 lastIndex;
    address immutable public LOCKER = 0xBF6cc8087327BCf80cAF3633B0315bdf397C3657;
    // ICO tracker
    uint256 public raisedBNB = 0;
    // uint256 public soldToken = 0;
    uint256 public bnbToLiquidity = 0;
    // uint256 public providedLiquidity = 0;
    bool public isCanceled =  false;
    bool public isFinalized =  false;

    // distribution status
    bool distributionStarted = false;
    mapping(address => uint256) private purchase;
    mapping(address => uint256) private spentBNB;

    // Some Events
    event Purchase(address indexed _account, uint256 _value,uint256 _id);

    // Pancake info
    address immutable public pancakeRouterAddress = 0x701d734A7AcA88429a516862c09eE8fF7893B145;
    IPancakeRouter02 pancakeSwapRouter;
    address public pancakeSwapPair;


    //vesting
    
    struct VestingPriod{
        uint percent;
        uint startTime;
        uint vestingCount;
       uint MaxClaim;   
    }
    
    uint maxPercent;
    bool Vesting;
    uint VestingCount;
    uint public totalSent;

    VestingPriod _vestingPeriod;

    mapping(uint => VestingPriod ) public PeriodtoPercent;
    mapping(address => uint) private TotalBalance;
    mapping(address => uint) private claimCount;
    mapping(address => uint) private claimedAmount;
    mapping(address => uint) private claimmable;



    // Contract Creation
    constructor(ICOparam memory _data){
        icoInfo = _data;
        Vesting = icoInfo.data.Vesting;
    }

    function onlyFactory() internal virtual {
        require(msg.sender == icoInfo.factory,"FO");
    }

    function setIsKYCAndAudit(bool kyc,bool audit) public{
        onlyFactory();
        isKYC = kyc;
        isAudit = audit;
    }

    function getPairAddress() external virtual{
        // onlyFactory();
        IPancakeRouter02 _uniswapV2Router = IPancakeRouter02(pancakeRouterAddress);
        address _uniswapV2Pair = IPancakeFactory(_uniswapV2Router.factory())
        .getPair(icoInfo.data.tokenAddress, _uniswapV2Router.WETH());
        pancakeSwapPair = _uniswapV2Pair;
        pancakeSwapRouter = _uniswapV2Router;
    }

    function setPairAddress() external virtual{
        onlyFactory();
        IPancakeRouter02 _uniswapV2Router = IPancakeRouter02(pancakeRouterAddress);
        address _uniswapV2Pair = IPancakeFactory(_uniswapV2Router.factory())
            .createPair(icoInfo.data.tokenAddress, _uniswapV2Router.WETH());
        pancakeSwapPair = _uniswapV2Pair;
        pancakeSwapRouter = _uniswapV2Router;
    }
    function checkOwner() internal view{
        require(icoInfo.owner == msg.sender,"OW");
    }

    // function checkFactory() internal view{
    //     require(icoInfo.factory == msg.sender, "OF");
    // }
    // Receive Function
    receive() external payable{
        buyTokens();
    }



    // Other functions
    function buyTokens() public virtual payable{
        // Check start and end Time
        require(icoInfo.data.presaleStartTime <= block.timestamp, "NS");
        require(icoInfo.data.presaleEndTime > block.timestamp,"IE");
     
 
        uint256 ratePerBNB;

        if(raisedBNB <= icoInfo.data.softCap)
        {
            ratePerBNB = icoInfo.data.presaleSupply/icoInfo.data.softCap;
        } else 

            ratePerBNB = icoInfo.data.presaleSupply/raisedBNB;

        //// Calculate Amount
        uint256 totalReceivable = ratePerBNB * msg.value;
        
        require(totalSent+totalReceivable <= icoInfo.data.presaleSupply, "TM");

        totalSent +=totalReceivable;
        // if(totalSent >= icoInfo.data.presaleSupply){
        //     totalSent -=totalReceivable;
        //     revert("TM");
        // } else {

        raisedBNB += msg.value;
   
        TotalBalance[msg.sender] +=totalReceivable;

        spentBNB[msg.sender] = spentBNB[msg.sender].add(msg.value);
        purchase[msg.sender] = purchase[msg.sender].add(totalReceivable);
    

        emit Purchase(msg.sender, totalReceivable,icoInfo.id);

        
        

    }
    
    function getContribution(address _user) public view returns(uint256){
        return spentBNB[_user];
    }

    function getReceivableToken(address _user) public view returns(uint256){
        return purchase[_user];
    }

    function claimToken() public {
      // Check if ended
        require(icoInfo.data.presaleEndTime < block.timestamp,"INE");
        // Check if Canceled
        require(!isCanceled,"IC");
        require(isFinalized,"WFF");
    
        uint bal = purchase[msg.sender];
        delete purchase[msg.sender];
        delete spentBNB[msg.sender];
        
        IERC20(icoInfo.data.tokenAddress).transfer(msg.sender, bal);
    }

    function emergencyWithdraw(uint256 amount_) public {
        require(icoInfo.data.presaleEndTime > block.timestamp,"TO");
        require(!isCanceled,"PC");
        require(spentBNB[msg.sender] >= amount_,"NA");
        uint256 fees = amount_ * 1000 / 10000;
        uint256 receivable = amount_ - fees;
        raisedBNB = raisedBNB.sub(amount_);

        uint256 ratePerBNB;
             if(raisedBNB <= icoInfo.data.softCap)
        {
            ratePerBNB = icoInfo.data.presaleSupply/icoInfo.data.softCap;
        } else 
        
        ratePerBNB = icoInfo.data.presaleSupply/raisedBNB;

        purchase[msg.sender] -= (amount_ * ratePerBNB);
        spentBNB[msg.sender] -= amount_;
        payable(msg.sender).transfer(receivable);
        payable(icoInfo.fees.AdminWalletAddress).transfer(fees);
    }
    function cancelPresale() public virtual{
        // onlyFactory();
        require(block.timestamp - icoInfo.data.presaleEndTime > 48 * 3600,"48H");
        _cancelPresale();
    }
    function claimRefund() public{
        // Check if ended
        // require(icoInfo.data.presaleEndTime < block.timestamp,"INE");
        // Check if failed or canceled
          require(!isFinalized,"IF");
        require(raisedBNB < icoInfo.data.softCap,"SC");
        require(isCanceled,"INC");
        require(icoInfo.data.presaleEndTime < block.timestamp,"NE");
        
        payable(msg.sender).transfer(spentBNB[msg.sender]);
        purchase[msg.sender] = 0;
        spentBNB[msg.sender] = 0;
    }

    function _provideLiquidity(uint256 bnbAmount) internal virtual{
        uint256 exchangeListingRateBNB = icoInfo.data.presaleSupply/raisedBNB;
        uint256 tokenAmount = exchangeListingRateBNB * bnbAmount;
        IERC20 token = IERC20(icoInfo.data.tokenAddress);
        token.approve(pancakeRouterAddress, tokenAmount);

        // add the liquidity
        pancakeSwapRouter.addLiquidityETH{value: bnbAmount}(
            icoInfo.data.tokenAddress,
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this), // Liquidity Locker or Creator Wallet
            block.timestamp
        );
    }
    // Make it only owner
    function endSale() public virtual{
        checkOwner();
        require(!isCanceled,"PC");
        
        if(raisedBNB < icoInfo.data.softCap){
            _cancelPresale();
        }else{

        require(icoInfo.data.softCap <= raisedBNB,"SE");
        require(icoInfo.data.presaleEndTime < block.timestamp,"NE");
    
            IERC20 token = IERC20(icoInfo.data.tokenAddress);
            
            // _provideLiquidity(bnbToLiquidity);
            _distribute();
            if(icoInfo.data.lockLiquidity){
                uint256 _amount = IERC20(pancakeSwapPair).balanceOf(address(this));
                _lockLPTokens(_amount, icoInfo.owner,icoInfo.data.liquidityLockTime);
            }
            // //// Distribute Fees
            // // payable(icoInfo.fees.AdminWalletAddress).transfer(icoInfo.fees.feesBNB * address(this).balance / 10000);
        
        uint256 adminToken = icoInfo.data.presaleSupply * icoInfo.fees.feesTokenAdmin / 10000;
      
        uint256 stakeToken = icoInfo.data.presaleSupply * icoInfo.fees.feesTokenStaking / 10000;
        
            token.transfer(icoInfo.fees.AdminWalletAddress, adminToken);
            token.transfer(icoInfo.fees.StakingWalletAddress, stakeToken);
            // purchase[icoInfo.fees.AdminWalletAddress] = 0;
            // purchase[icoInfo.fees.StakingWalletAddress] = 0;
            // // Receive Remaining Amount
            // payable(icoInfo.owner).transfer(address(this).balance);

            remainingTokens();

           isFinalized = true;

        }
    }
    function remainingTokens() public {
        checkOwner();
        
        IERC20 token = IERC20(icoInfo.data.tokenAddress);
        
       uint ratePerBNB = icoInfo.data.presaleSupply/raisedBNB;

        uint claimmableToken = raisedBNB * ratePerBNB;

          uint256 bal = token.balanceOf(address(this)) - claimmableToken;
            if(icoInfo.data.burnRemaining && bal > 0){
                token.transfer(DEAD,bal);
            }else 
            if(bal > 0){
                token.transfer(icoInfo.owner,bal);
            }

    }
    function getPresaleSupply() external view returns(uint){
        return icoInfo.data.presaleSupply;
    }

    function getBalance() external view returns(uint){
        
        IERC20 token = IERC20(icoInfo.data.tokenAddress);

        uint256 bal = token.balanceOf(address(this));

        return bal;
    }

    function _distribute() internal {
        uint256 fees = icoInfo.fees.feesBNB * icoInfo.data.softCap / 10000;
        bnbToLiquidity = icoInfo.data.liquidityPercent * icoInfo.data.softCap/10000;
        // Disburse the Rest to dev
        payable(icoInfo.owner).transfer(address(this).balance - bnbToLiquidity);
        // Provide Liquidity
         _provideLiquidity(bnbToLiquidity - fees);
        // Send Remaining Balance to AdminWallet
        payable(icoInfo.fees.AdminWalletAddress).transfer(address(this).balance);
    }
         
    function cancelSale() public virtual{
        checkOwner();
        require(!isCanceled,"PAC");
        _cancelPresale();
    }

    function _cancelPresale() internal virtual{
        IERC20 token = IERC20(icoInfo.data.tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(icoInfo.owner,balance);
        isCanceled = true;
    }

    // Lock LP token
    function _lockLPTokens(uint256 _amount,address _owner,uint256 _liquidityLockTime) internal virtual{
        //  Check Balance
        IERC20 token = IERC20(icoInfo.data.tokenAddress);
        require(token.balanceOf(address(this)) >= _amount,"IB");
        ILock locker = ILock(LOCKER);
        locker.lock(icoInfo.data.tokenAddress, _owner , _liquidityLockTime, _amount);
    }


    //Vesting 

    function UpdateVesting(bool newStatus) external{
        require(Vesting != newStatus);
        Vesting = newStatus;
    }
    

    function setVesting(uint StartTime, uint StartPercentage) external {
        require(icoInfo.data.presaleEndTime < StartTime,"IE");
        require(Vesting, "VF");//Vesting was not set to true
           VestingCount++;
           maxPercent += StartPercentage;
        if(maxPercent > 100){
            maxPercent -=StartPercentage;
            revert ();
        }
        else {
            require(StartTime > PeriodtoPercent[VestingCount-1].startTime);
        PeriodtoPercent[VestingCount] = VestingPriod({
            percent : StartPercentage,
            startTime : StartTime,
            vestingCount : VestingCount,
              MaxClaim : maxPercent
        });

        }
    }

  
    function Vestingclaim() external {
        require(Vesting, "NV");
        require(isFinalized, "NF");
        require(claimCount[msg.sender] <= VestingCount,"CC");//Claiming Complete
        claimCount[msg.sender] ++;

        for(uint i = claimCount[msg.sender]; i<= VestingCount; i++){
            if(PeriodtoPercent[i].startTime <= block.timestamp){
                claimmable[msg.sender] +=PeriodtoPercent[i].percent;
            }
            else 
            break;
        }
        
        IERC20 token = IERC20(icoInfo.data.tokenAddress);

        require(claimmable[msg.sender] <= 100);
        

        uint _amount = (claimmable[msg.sender] *100) * TotalBalance[msg.sender]/10000;

        purchase[msg.sender] -= _amount;
        claimedAmount[msg.sender] += claimmable[msg.sender]; 
  
        delete claimmable[msg.sender];

        token.transfer(msg.sender, _amount);


     
    }

    
    function requestKYCandAudit() public view returns(address){
        checkOwner();
        return address(this);
    }


}