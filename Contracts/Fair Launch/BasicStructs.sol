// SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.0;

struct ICOBase{
    address presaleAddress;
    ICOparam ico;
}

struct DataParam{
    string  icoName;
    address  tokenAddress;
    uint256  presaleSupply;
    uint256  presaleStartTime;
    uint256  presaleEndTime;
    string  listingOn;
    uint256  softCap;
    bool  lockLiquidity;
    bool  burnRemaining;
    uint256  liquidityLockTime;
    uint256 liquidityPercent;
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