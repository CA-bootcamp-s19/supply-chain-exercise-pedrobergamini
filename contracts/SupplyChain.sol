/*
    This exercise has been updated to use Solidity version 0.6
    Breaking changes from 0.5 to 0.6 can be found here: 
    https://solidity.readthedocs.io/en/v0.6.12/060-breaking-changes.html
*/

pragma solidity >=0.6.0 <0.7.0;

contract SupplyChain {

  address public owner;

  uint public skuCount;

   struct Item {
    string name;
    uint sku;
    uint price;
    State state;
    address payable buyer;
    address payable seller;
  }

  mapping (uint => Item) public items;

  enum State { ForSale, Sold, Shipped, Received }

  event LogForSale(uint indexed sku);
  event LogSold(uint indexed sku);
  event LogShipped(uint indexed sku);
  event LogReceived(uint indexed sku);

  modifier onlyOwner() { require(msg.sender == owner); _; }
  modifier verifyCaller(address _address) { require (msg.sender == _address); _;}
  modifier paidEnough(uint _price) { require(msg.value >= _price); _;}
  modifier checkValue(uint _sku) {
    //refund them after pay for item (why it is before, _ checks for logic before func)
    _;
    uint _price = items[_sku].price;
    uint amountToRefund = msg.value - _price;
    items[_sku].buyer.transfer(amountToRefund);
  }

  modifier forSale(uint sku) {
    require(items[sku].state == State.ForSale 
      && 
      items[sku].seller != address(0), 'Error: item not for sale');
    _;
  }
  modifier sold(uint sku) {
    require(items[sku].state == State.Sold, 'Error: item not sold');
    _;
  }
  modifier shipped(uint sku) {
    require(items[sku].state == State.Shipped, 'Error: item not shipped');
    _;
  }
  modifier received(uint sku) {
    require(items[sku].state == State.Received, 'Error: item not received');
    _;
  }


  constructor() public {
    owner = msg.sender;
  }

  function addItem(string memory _name, uint _price) public returns (bool){
    emit LogForSale(skuCount);
    items[skuCount] = Item({name: _name, sku: skuCount, price: _price, state: State.ForSale, seller: msg.sender, buyer: address(0)});
    skuCount = skuCount + 1;
    return true;
  }

  function buyItem(uint sku) public payable forSale(sku) checkValue(sku) {
    Item storage item = items[sku];
    require(msg.value >= item.price);
    item.buyer = msg.sender;
    item.state = State.Sold;
    item.seller.transfer(item.price);

    emit LogSold(sku);
  }

  function shipItem(uint sku) public sold(sku) {
    Item storage item = items[sku];
    require(msg.sender == item.seller);
    item.state = State.Shipped;
    
    emit LogShipped(sku);
  }

  function receiveItem(uint sku) public shipped(sku) {
    Item storage item = items[sku];
    require(msg.sender == item.buyer);
    item.state = State.Received;

    emit LogReceived(sku);
  }


  function fetchItem(uint _sku) public view returns (string memory name, uint sku, uint price, uint state, address seller, address buyer) {
    name = items[_sku].name;
    sku = items[_sku].sku;
    price = items[_sku].price;
    state = uint(items[_sku].state);
    seller = items[_sku].seller;
    buyer = items[_sku].buyer;
    return (name, sku, price, state, seller, buyer);
  } 

}
