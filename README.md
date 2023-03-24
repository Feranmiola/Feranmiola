Hello,

I am Feranmi Ola

I am an expert Blockchaindeveloper with solidity and development on the Ethereum Blockchain and Binance Smart Chain.

Please reach me through my email - osunjuyigbeiyin@gmail.com


/////////////////////////////////////////////////////////////////////////////


This repository holds some major projects i have taken on in my carrer, some of these are personal and were just made for fun and others are professional smart contracts that may or may not be deployed on the main net at the time you are seeing this.
DO NOT use these contracts for a real world purpose as they are, they are versions of the original contracts may not be procution ready yet, USE AT YOUR OWN RISK.


/////////////////////////////////////////////////////////////////////////////

1. Mining Contracts-
  The idea is to create a contract that simulates a mining program which its purpose is to mine a token for a price in ETH. You should be able to tell from the way they were implemented that they were written in the first month of my experience with blockchain development. Revisions may be done in the future.
  V1 - This allows you to mine the token(Test token) for a price in eth, the more you pay,the more you can mine. The contract is not flexible enough as a lot of areas were hardcoded, example is the levelsetter function that requires you to send EXACTLY 0.01, 0.1 OR 1 ETH, anything more or less would result in a fail. 
  V2 - This takes the contract a step further by allowing people to start a mine for a token of their choice, Just like V1, user pay, and then they mine, but here the payments, this is a little more advanced as it lets users mine and cancel their mine to claim their money back.
  
/////////////////////////////////////////////////////////////////////////////
2. PaymentSplitter contracts - 
  I saw a payment splitter implementation by thirdweb and i thought i could do something simmilar. 
  These contracts would recieve tokens or ETH and distribute them acccordingly to different addresses. The recieving addresses would have been set along with the percentage they would recieve when the recieved tokens are distributed.
  V1 - This takes in ETH and then distributes it to addresses set in the contract based on whatever shares they were assigned.
  V2 - Same implementation as V1 but wuth ERC tokens.
  
  //////////////////////////////////////////////////////////////////////////
  
3. Vesting Contract - 
  This is just a basic idea of a vesting method that gives total freedom in a case of a launchpad, this method is implemented in the TokenPresale, LaunchPad and Lock contracts.
  It allows users to be able to set the exact percentage and the exact time for each percentage they wish to release, this is quite differernt to the popular implementation done by PinkSale that uses a cycle system.
  
////////////////////////////////////////////////////////////////////////////////
4. Staking Pool-
  The logic here is that users stake for a particular duration and they get a form of reward after.
  V1 - This has four contracts the pool, and the three month pools (month 1, month 3 and month 6 which is one month, three months and six months respectively), only the durations and the minimum stake amount varies for all three month contracts. 
  The pool contract may be called the motherpool, it recieves tokens from ICOs and distributes them to the month contracts, where usere can stake and claim them at the end of their stakeing duration, the higher the stake amount and duration, the more rewards you get. 
  Edit- A few limitations to the contract, provisions arent peoperly made for a single address staking with two tokens even though it accepts more than one token, you also can not stake more than once, the old stake would be overwritten and the initial stake tokens would be lost in the contract, claim rewards function seems a bit funky, it looks like it requires people to claim at exactly the claim time which is not very user friendly.
  
  V2 - This is very different to V1, but is based on the mining V2 contract, it allows people to deploy new pool contracts where users can access it and stake with the token provided.
  
  V3 - This is an improvement to V1. it eliminates a token making life easier, and it no longer overwrites stakes in the pool.

//////////////////////////////////////////////////////////////////////////////
5. Betting -
  This is a concept of a blockchain based betting platform, This implements a PVP betting system where it is you against another person or a group of people.
  It has three contracts, the P2P where you stake against the decision of one other person, a pool contract where you or your group stake(s) against the decision of another group and then the database contract that acts as the storage(I just named it database so it looks cool).
  These contracts were written with an upgradable method of seperating the logic and the storage.
  
//////////////////////////////////////////////////////////////////////////////
6. Mint -
  This contract probably has more files than it needs to
  It practically deploys a new token on the network for anybody that calls the function create new token in the proxy contract .
