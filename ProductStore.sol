// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ProductIdentification.sol';

contract ProductStore {
	address public admin;
	address payable public product_deposit_address;
	address public product_identification_address;
	ProductDeposit product_deposit;
	ProductIdentification product_identification;
	mapping(uint => uint) product_price; // assigns the product's ID to its price
	mapping(uint => Product) product_stock; // assigns the product's ID to its stock
  	event receivedFunds(address, uint);
	event fallbackCall(string);
	event ProductInfo(uint, string, uint);

	struct Product{
        uint id;
        string name;
        address producerAddress;
        uint volume; 
    }

	constructor(){
		admin = msg.sender;
		// product_deposit = new ProductDeposit();
		// product_identification = new ProductIdentification();
	}

	function setDepositAddress(address payable _depositAddress) public onlyOwner{
		product_deposit_address = _depositAddress;
		product_deposit = ProductDeposit(product_deposit_address);
		// product_deposit.getDepositAddress();
	}

	function setIdentificationAddress(address payable _identificatonAddress) public onlyOwner{
		product_identification_address = _identificatonAddress;
		product_identification = ProductIdentification(product_identification_address);
		//product_identification.getIdentificationAddress();
	}

	modifier onlyOwner() {
        require(msg.sender == admin, "Only the owner can call this function");
        _;
  	}

	function addToStore(uint _product_ID, uint _volume) public onlyOwner{
		/*
		varianta initiala de requirements
		uint available_volume = product_deposit.getProductVolume(_product_ID);
		require(available_volume >= _volume, "Cannot add this many products to the store!");
		address payable producer_address = payable(product_identification.getProducer(_product_ID));
		address assignedStore = product_deposit.getAssignedStore(producer_address);
		require(assignedStore == address(this), "This store is not authorized!"); // verifica adresa contractului
		*/
		require(product_deposit.getProductVolume(_product_ID) >= _volume, "Cannot add this many products to the store!");
		require(product_deposit.getAssignedStore(payable(product_identification.getProducer(_product_ID))) == address(this), "This store is not authorized!"); // verifica adresa contractului
		product_deposit.withdrawProduct(true, payable(address(this)), _product_ID, _volume);
		product_stock[_product_ID] = Product(_product_ID, product_identification.getProduct( _product_ID).name, payable(product_identification.getProducer(_product_ID)), _volume);
	}

	function setProductPrice(uint _product_ID, uint _price) public onlyOwner{
		product_price[_product_ID] = _price;
	}

	// verificare produs in stoc sau inregistrat
	function checkProduct(uint _product_ID) public view returns (bool){
		require(product_identification.isProductRegistered(_product_ID) == true, "Product is not registered!");
		require(product_stock[_product_ID].volume > 0, "Product out of stock!");
		return true;
	}

	// afisarea informatiilor despre un produs - DE VERIFICAT
	function getInfoProduct(uint _product_ID) public view returns(Product memory){
		require(checkProduct(_product_ID), "Product does not exist");
		return product_stock[_product_ID];
	}

	function purchaseProduct(uint _product_ID, uint _volume) public payable {
		require(checkProduct(_product_ID) == true, "Product is not registered or out of stock!");
		require(product_stock[_product_ID].volume >= _volume, "Cannot purchase this many pieces of this product!");
		// product_stock[_product_ID].volume -= _volume; -> initial scadeam volumul produsului inainte de a transfera banii
		address payable producer_address = payable(product_identification.getProducer(_product_ID));
		uint price = product_price[_product_ID] * _volume;
		producer_address.transfer(price / 2);
		product_stock[_product_ID].volume -= _volume;
	}

	receive () payable external {
      	emit receivedFunds(msg.sender, msg.value);
  	}

	fallback () external {
    	emit fallbackCall("Falback Called!");
  	}
}