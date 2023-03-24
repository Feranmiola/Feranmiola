// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct ICOBase{
    address presaleAddress;
    ICOparam ico;
}
struct DataParam{
    string  icoName;
    address  tokenAddress;
    uint256  presaleSupply;
    uint256  liquiditySupply;
    uint256  presaleStartTime;
    uint256  presaleEndTime;
    string  listingOn;
    uint256  softCap;
    uint256  hardCap;
    uint256  ratePerBNB;
    uint256  exchangeListingRateBNB;
    uint256  minAmount;
    uint256  maxAmount;
    bool  lockLiquidity;
    bool  burnRemaining;
    uint256  liquidityLockTime;
    bool whiteListEnabled;
    uint256 whitelistLastDate;
    bool Vesting;
}


struct ICOparam{
    uint256  id;
    bool  isLive;
    address  owner;
    address  factory;

    DataParam data;

    // Fixed Fees
    Fees fees;
}

struct Fees{
    uint256  feesBNB;
    uint256  feesTokenAdmin;
    uint256  feesTokenStaking;
    address  StakingWalletAddress;
    address  AdminWalletAddress;
}

struct vestingStruct{
    uint256 firstPercent;
    uint256 firstReleaseTime;
    uint256 cyclePercent;
    uint256 cycleReleaseTime;
    uint256 cycleCount;
}