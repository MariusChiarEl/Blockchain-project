// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ProductIdentification.sol';

contract ProductDeposit {
  address payable public admin;
  address public product_identification_address;
  uint public maxVolume;
  uint public depositFee;
  mapping (uint => uint) public productDeposited; // maps the product's id to the deposited volume
  ProductIdentification product_identification;
  mapping(address => address) producer_to_store; // maps the producer's address to its store's address
  event fallbackCall(string);
  event receivedFunds(address, uint);

  constructor(){
    admin=payable(msg.sender);
  }
  
  fallback () external {
    emit fallbackCall("Falback Called!");
  }

  modifier onlyOwner() {
        require(msg.sender == admin, "Only the owner can call this function");
        _;
  }
	
  function setIdentificationAddress(address _productIdentificationAddress) public onlyOwner{
		product_identification_address = _productIdentificationAddress;
       // product_identification.getIdentificationAddress();
	}

  function getProductVolume(uint _product_ID) public view returns (uint){
    return productDeposited[_product_ID];
  }

  function getAssignedStore(address payable _producer_address) public view returns (address){
    return producer_to_store[_producer_address];
  }

	// Setarea de catre proprietar a unei taxe publice unica de depozitare pe unitate de volum, si a unui volum maxim al depozitului.
	function setDepositFeePerUnit(uint _fee) public onlyOwner {
		depositFee = _fee;
  }
    
	function setMaximumvolume(uint _volume) public onlyOwner{
		maxVolume = _volume;
	}
    
  function depositProduct(uint _productID, uint _volume) public payable{
    // Inregistrarea depozitarii unui produs
    product_identification = ProductIdentification(product_identification_address);
    require(product_identification.isProducerRegistered(msg.sender) == true, "Producer not authorized!");
    // verifcare volum din Product identification
    require(product_identification.getProduct(_productID).volume >= _volume, "You don't have that many products");
	  require(_volume <= maxVolume, "Volume too high!");
    require(msg.value >= depositFee * _volume, "Insufficient funds!");
    //admin.transfer(msg.value); -> initial, a fost scris aici
	  productDeposited[_productID] = _volume;   
    product_identification.withdrawVolume(msg.sender, _productID, _volume); // am retras volumul depus in depozit
    maxVolume -= _volume;
    admin.transfer(msg.value); // acum respecta principiul checks-effects-interactions
  }

  function registerStore(address _storeAddress) public {
    require(product_identification.isProducerRegistered(msg.sender), "Producer not authorized!");
    require(producer_to_store[msg.sender] == payable(address(0)), "The producer has already registered a store!");
    producer_to_store[msg.sender] = _storeAddress;
  }

  function withdrawProduct(bool producer_or_store, address payable _destinationAddress, uint _productID, uint _volume) public{
    // _destinationAddress poate fi producator sau magazin
    /*
    initial, verificam daca producatorul/magazinul este inregistrat folosind doua if-uri care contineau requirements
    am inlocuit aceasta structura cu un requirement singular
    if(producer_or_store == false){ // false => producer
        require(product_identification.isProducerRegistered(_destinationAddress), "Producer not authorized!");
        product_identification.addVolume(_destinationAddress, _productID, _volume); // adaugarea la loc a produselor producatorlui
    } else {
        require(producer_to_store[product_identification.getProducer(_productID)] == _destinationAddress, "Store not authorized");
    }
    */
    require((!producer_or_store && product_identification.isProducerRegistered(_destinationAddress)) || (producer_or_store && producer_to_store[product_identification.getProducer(_productID)] == _destinationAddress), "Not authorized!!");
    require(productDeposited[_productID] >= _volume, "Cannot withdraw that many products!");

    if(producer_or_store == false){ // false => producer
      product_identification.addVolume(_destinationAddress, _productID, _volume); // adaugarea la loc a produselor producatorlui
    }

    productDeposited[_productID] -= _volume;
    maxVolume += _volume;
  }

  function getDepositAddress() public view returns (address payable) {
    return payable(address(this));
  }
    
  receive () payable external {
    emit receivedFunds(msg.sender, msg.value);
  }

}