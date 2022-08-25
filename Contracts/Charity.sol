//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract Charity{
    //Declaring state Variables and events 
   address public foundationAddress;
   //we want to keep track of the total amount spent for charity and the total amount that has been donated
   uint256 public totalDonations;
   uint256 public totalSpent;

   //we would also keep track of the people who donated and the amount they donated
   mapping(address => uint256) public Donators;

   //now a few events
   event Donated(address indexed donator, uint256 amount);
   event Spent(uint256 amount);

   //using a constructor to assign the foundation address
   constructor(){
       foundationAddress = payable(msg.sender);
   }

   //Defining Functions

    //in order to receive ether, this contracts needs a fallback or recieve functions 
   
    receive() external payable{
      donate();
    }


   function donate() public payable{

       Donators[msg.sender] += msg.value;
       totalDonations += msg.value;

       //now emit the donated event
       emit Donated(msg.sender, msg.value);
   }
  


   //Now we need a modifier that would check the balance when withdrawing 

   modifier enoughBalance(uint amount){
       require(amount <= address(this).balance, "Insufficient Balance");
       _;
   }

   //and another modfier to check if the caller is the set foundation address

   modifier onlyOwner{
       require(msg.sender == foundationAddress, "Not foundation Address");
       _;
   }


    //Incase the foundation address changes, this function is here so the old address would be able to swithc to a new one
   function changeFoundationAddress(address newAddress) external onlyOwner{
       //a check to make sure the current address is not the same as the one being entered
       require(newAddress!= foundationAddress, "Already existing");
       foundationAddress = newAddress;
   }

   function Withdraw(uint256 amount) external onlyOwner enoughBalance(amount){
       payable(foundationAddress).transfer(amount);

       emit Spent(amount);
   }

}
