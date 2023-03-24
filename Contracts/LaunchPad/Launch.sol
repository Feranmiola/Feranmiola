//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ICO.sol";


contract Launch is Initializable{
    Idatabase public dataStorage;

    address public DEAD;
    

    event PresaleCreated(address indexed created, address indexed token);

    function initialize() external initializer{        
        DEAD = 0x000000000000000000000000000000000000dEaD;
        
        dataStorage = Idatabase(0xDdA2f34BE0Cefd1AeF7FEF253767aD74Cd93Ec02);
    }



    receive() external payable{}

    function cancelPresale(address presaleAddress) public{
        require(dataStorage.getAdmin() == msg.sender);

        ICO ico = ICO(payable(presaleAddress));

        ico.adminCancelPresale();

    }


    function createNewICO(DataParam calldata newICOData, vestingStruct calldata vesting) external returns(address){

        // Create details
        IERC20Upgradeable token = IERC20Upgradeable(newICOData.tokenAddress);

        ICOparam memory _icoBase = _makeICOObject(dataStorage.getLastIndex(),newICOData);

        ICO icoContract = new ICO();

        address newcontract = address(icoContract);

        ICO(payable(newcontract)).initialize(_icoBase, vesting);
        ICO(payable(newcontract)).setVesting();

        //ICO(payable(newcontract)).setPairAddress();

        dataStorage.setPresaleDetails(payable(newcontract), _icoBase);
        
        

        
        IERC20Upgradeable ssn = IERC20Upgradeable(dataStorage.getFeeToken());

        ssn.transferFrom(msg.sender, dataStorage.getAdmin(), dataStorage.getLunchAdminWalletFee());

        if(dataStorage.getLunchStakingPoolFee() > 0){
            ssn.transferFrom(msg.sender, dataStorage.getStakingPoolAddress(), dataStorage.getLunchStakingPoolFee());
        }

        ssn.transferFrom(msg.sender, DEAD, dataStorage.getBurnFee());

        // Transfer Token
        uint amount = _totalFees(newICOData.liquiditySupply, newICOData.presaleSupply);
        token.transferFrom(msg.sender, address(icoContract), amount);
        

        emit PresaleCreated(address(icoContract),newICOData.tokenAddress);

        return address(icoContract);

    }




    function _makeICOObject(uint256 _lastIndex,DataParam calldata newICOData) internal view returns (ICOparam memory){
        ICOparam memory x = ICOparam(
            _lastIndex,
            true, // IsLive true by default
            msg.sender,
            address(this),
            newICOData,
            Fees(
            dataStorage.getFeesBNBPercent(),
            dataStorage.getICOAdminWalletFee(),
            dataStorage.getICOStakingPoolFee(),
            dataStorage.getStakingPoolAddress(),
            dataStorage.getAdmin()
        )
        );
        return x;
    }


    function _totalFees(uint256 _liquiditySupply, uint256 _presaleSupply) internal view returns(uint256){
        uint256 extraTokenForLiquidity =  _liquiditySupply * _presaleSupply / 10000 ;
        uint256 extraTokenForAdminFees = _presaleSupply * dataStorage.getICOStakingPoolFee() / 10000;
        uint256 totalFees = _presaleSupply * dataStorage.getICOAdminWalletFee() / 10000;

        return (_presaleSupply + extraTokenForLiquidity + extraTokenForAdminFees + totalFees);
    }

    function changeDatabase(address newDatabase) external{
        require(dataStorage.getAdmin() == msg.sender);

        dataStorage = Idatabase(newDatabase);
    }


}