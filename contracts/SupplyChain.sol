// Implement the smart contract SupplyChain following the provided instructions.
// Look at the tests in SupplyChain.test.js and run 'truffle test' to be sure that your contract is working properly.
// Only this file (SupplyChain.sol) should be modified, otherwise your assignment submission may be disqualified.

pragma solidity ^0.5.0;

contract SupplyChain {

  address payable owner;
  // Create a variable named 'itemIdCount' to store the number of items and also be used as reference for the next itemId.
  uint itemIdCount = 0;
  // Create an enumerated type variable named 'State' to list the possible states of an item (in this order): 'ForSale', 'Sold', 'Shipped' and 'Received'.
  enum State {
    ForSale,
    Sold,
    Shipped,
    Received
  }
  // Create a struct named 'Item' containing the following members (in this order): 'name', 'price', 'state', 'seller' and 'buyer'. 
  struct Item {
    string name;
    uint price;
    State state;
    address payable seller;
    address buyer;
  }
  // Create a variable named 'items' to map itemIds to Items.
  mapping (uint => Item) items;
  // Create an event to log all state changes for each item.
  event ChangeState(uint _id, State);

  constructor() public{
    owner = msg.sender;
  }

  // Create a modifier named 'onlyOwner' where only the contract owner can proceed with the execution.
  modifier onlyOwner(){
    require(msg.sender==owner, "onlyowner");
    _;
  }
  // Create a modifier named 'checkState' where the execution can only proceed if the respective Item of a given itemId is in a specific state.
  modifier checkState (uint _id, State _state){
    require(items[_id].state == _state, "is not specific state");
    _;
  }
  // Create a modifier named 'checkCaller' where only the buyer or the seller (depends on the function) of an Item can proceed with the execution.
  modifier checkCaller (uint _id, bool isSeller){
    isSeller? require(items[_id].seller == msg.sender, "you are not seller") : require(items[_id].buyer == msg.sender, "you are not buyer");
    _;
  }
  // Create a modifier named 'checkValue' where the execution can only proceed if the caller sent enough Ether to pay for a specific Item or fee.
  modifier checkValue (uint _value){
    require(msg.value >= _value, "is not enough Ether");
    _;
  }

  modifier checkParam (string memory _name, uint _price){
    bytes memory tempEmptyStringTest = bytes(_name);
    require(tempEmptyStringTest.length != 0 && _price > 0,"name and price is must input");
    _;
  }


  // Create a function named 'addItem' that allows anyone to add a new Item by paying a fee of 1 finney. Any overpayment amount should be returned to the caller. All struct members should be mandatory except the buyer.
  function addItem (string memory _name, uint _price) checkValue(1 finney) checkParam(_name, _price) public payable{
    items[itemIdCount] = Item(_name, _price, State.ForSale, msg.sender, address(0));
    itemIdCount++;
    if(msg.value > 1 finney) {
      msg.sender.transfer(msg.value - 1 finney);
    }

    emit ChangeState(itemIdCount-1, State.ForSale);
  }
  // Create a function named 'buyItem' that allows anyone to buy a specific Item by paying its price. The price amount should be transferred to the seller and any overpayment amount should be returned to the buyer.
  function buyItem (uint _id) checkState(_id, State.ForSale) external payable {
    Item storage targetItem = items[_id];
    if(msg.value > targetItem.price){
      msg.sender.transfer(msg.value-targetItem.price);
      targetItem.seller.transfer(targetItem.price);
    }
    targetItem.state = State.Sold;
    targetItem.buyer = msg.sender;

    emit ChangeState(_id, State.Sold);
  }
  // Create a function named 'shipItem' that allows the seller of a specific Item to record that it has been shipped.
  function shipItem (uint _id) checkCaller(_id, true) checkState(_id, State.Sold) external{
    Item storage targetItem = items[_id];
    targetItem.state = State.Shipped;

    emit ChangeState(_id, State.Shipped);
  }
  // Create a function named 'receiveItem' that allows the buyer of a specific Item to record that it has been received.
  function receiveItem (uint _id) checkCaller(_id, false) checkState(_id, State.Shipped)  external{
    Item storage targetItem = items[_id];
    targetItem.state = State.Received;

    emit ChangeState(_id, State.Received);
  }
  // Create a function named 'getItem' that allows anyone to get all the information of a specific Item in the same order of the struct Item. 
  function getItem (uint _id) external view returns(string memory, uint, State, address, address){
    Item storage aItem = items[_id];
    return (aItem.name, aItem.price, aItem.state, aItem.seller, aItem.buyer);
  }
  // Create a function named 'withdrawFunds' that allows the contract owner to withdraw all the available funds.
  function withdrawFunds () external onlyOwner {
    owner.transfer(address(this).balance);
  }
}
