// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ProductDeposit.sol';
import './SampleToken.sol';

contract ProductIdentification{
    address payable public admin;
    uint public registrationFee;
    uint id = 0;
     SampleToken public tokenContract;
    event fallbackCall(string);
    

    struct Producer {
        address producerAddress;
        uint productsCount;
    }

    struct Product{
        uint id;
        string name;
        address producerAddress;
        uint volume; 
    }

    mapping (address => Producer) registeredProducers; // contains the data of each producer based on their address
	mapping (uint => Product) public registeredProducts; // registeredProducts[id]
    
    constructor(SampleToken _tokenContract) {
        admin = payable(msg.sender);
        tokenContract = _tokenContract;
    }

    modifier onlyOwner() {
        require(msg.sender == admin, "Only the owner can call this function");
        _;
    }

    // modifier onlyProducer(uint _productID){
    //     require(msg.sender == getProducer(_productID), "not authorized to withdraw products"); // doar producatorul obiectului poate retrage produse
    //     _;
    // }

    //setarea de catre proprietar a unei taxe publice de inregistrare producator.
     function setRegistrationFee(uint _fee) public onlyOwner {
        registrationFee = _fee;
    }

    // Inregistrarea unui producator, ce va memora adresa acestuia in starea contractului, contra taxei respective.
    function registerProducer() public payable {
        require(msg.value >= registrationFee, "Insufficient registration fee");
        // admin.transfer(registrationFee); // transfera taxa proprietarului  -> initial, transferul avea loc aici
        registeredProducers[msg.sender].producerAddress = msg.sender;
        registeredProducers[msg.sender].productsCount = 0; // number of products for a producer
        admin.transfer(registrationFee);
    }

   // inregistrarea unui producator cu plata in token
    function registerProducerWithTokens() public  {
        //n am pus payable ca accepta doar tokens
        require(tokenContract.allowance_left(msg.sender, address(this)) >= registrationFee, "Insufficient token allowance");
        tokenContract.transferFrom(msg.sender, admin, registrationFee); // transfera token catre admin ca si taxsa de inregitsrare
        //dupa ce transferul de tokens s a reusit, adresa producatorului este setata iar productsCount este initializat la zero
        registeredProducers[msg.sender].producerAddress = msg.sender;
        registeredProducers[msg.sender].productsCount = 0;
    }

    // Inregistrarea unui produs ce va putea fi facuta doar de catre unul dintre producatorii inregistrat (isProducerRegistered)
    // Un producator poate inregistra mai multe produse, ce vor fi retinute pe baza unui id unic per produs 
    //vor include ca informatie adresa producatorului, denumirea produsului si o valoare volumetrica a produsului
    function registerProduct(string memory _name, uint _volume)  public {
         // AM MODIFICAT ADRESA PRODUCATORULUI IN MSG.SENDER, DEOARECE PRODUCATORUL APELEAZA FUNCTIA
        require(isProducerRegistered(msg.sender),"Producer is not registered");
        registeredProducts[id] = Product(id, _name , msg.sender, _volume);
        id += 1;
    }

    function getBalance() view public returns (uint) {
      return address(this).balance;
  }
  //get the balance of tokens in the contract
    function getTokenBalance() view public returns (uint) {
        return tokenContract.balance_of(address(this));
    }

      // Posibilitatea verificarii pe baza adresei unui producator daca acesta este inregistrat.
    // if is registeredProducers mapping
    function isProducerRegistered(address _producerAddress) public view returns (bool) {
        return registeredProducers[_producerAddress].producerAddress != address(0);
    }
    
    function isProductRegistered(uint _productId) public view returns(bool) {
     	 return registeredProducts[_productId].producerAddress != address(0);
    }

	// Posibilitatea verificarii pe baza id-ului unui produs daca acesta este inregistrat,
    // si aflarea informatiilor despre acesta. (id, nume, adresa producator, volum)
     function getProduct(uint _productId) public view returns (Product memory) {
       	require(isProductRegistered(_productId), "Product is not registered");
        return registeredProducts[_productId]; 
    }

    function getIdentificationAddress() public view returns (address payable) {
    return payable(address(this)); // adresa contractului
    }

    function getProducer(uint _product_ID) public view returns (address){
        return registeredProducts[_product_ID].producerAddress;
    }

    // retragem volumul care s-a mutat in depozit
    function withdrawVolume(address _producerAddress, uint _productID, uint _volume) public {
        require(_producerAddress == getProducer(_productID), "not authorized to withdraw products"); // doar producatorul obiectului poate retrage produse
        registeredProducts[_productID].volume -= _volume;
    }

    function addVolume(address _producerAddress, uint _productID, uint _volume) public {
        require(_producerAddress == getProducer(_productID), "not authorized to withdraw products"); // doar producatorul obiectului poate retrage produse
        registeredProducts[_productID].volume += _volume;
    }



    //Functie fallback
    fallback () external {
        emit fallbackCall("Falback Called!");
    }
}
