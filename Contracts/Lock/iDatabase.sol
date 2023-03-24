// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


interface iDatabase {
    
    function getAdmin() external view returns(address);
    function getStakingPoolAddress() external view returns(address);
    function getTokenAddress() external view returns(address);
    function getDEadAddress() external view returns(address);
    function getERC20adr() external view returns(address);
    function get_token() external view returns(IERC20Upgradeable);
    function getBeneficiary() external view returns(address);
    function getAdminWalletFee() external view returns(uint);
    function getStakingPoolFee() external view returns(uint);
    function getBurnFee() external view returns(uint);
    function getTotalFee() external view returns(uint);
    function getStatus(address sender, uint index) external view returns(bool);
    function getLockTokens(address token_) external view returns(uint256);
    function getTransaction(address owner_, uint256 index)external view returns(IERC20Upgradeable, uint256, address, uint256, uint256, string memory, bool);
    function getId(address owner_, uint256 index)external view returns(uint256);
    function lpApprove( IERC20Upgradeable tkAdr, address spender, uint256 value) external;
    function checkBalance(address owner_ ) external view returns (uint);
    function lockLength(address owner_) external view returns (uint);
    function token(address owner_, uint index) external view returns (IERC20Upgradeable);
    function checkAllowance(IERC20Upgradeable token_, address user) external view returns (uint256);
    function beneficiary(address owner_, uint index) external view returns (address);
    function releaseTime(address owner_, uint index) external view returns (uint256);
    function amount(address owner_, uint index) external view returns(uint256);
    function checkBalance(IERC20Upgradeable token_, address owner_) external view returns (uint);



    function DatabaseRelease(address sender, uint index, address tokentoLock, uint amount) external;
    function DatabaseLock( address sender, address token_, address beneficiary_, uint256 releaseTime_, uint256 amount_, uint256 period_, string memory logoLink_) external returns(uint);
    function DatabaseLaunchLock(address sender, address token_, address beneficiary_, uint256 releaseTime_, uint256 amount_, string memory logoLink_) external returns(uint);



}