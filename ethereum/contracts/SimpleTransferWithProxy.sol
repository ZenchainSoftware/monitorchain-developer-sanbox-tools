pragma solidity ^0.4.21;

contract SimpleTransferWithProxy {
    address private owner;
    address private freezeProxy;
    function SimpleTransferWithProxy(){
        owner = msg.sender;
    }
    
    modifier restrictToOwner(){
        require(msg.sender == owner);
        _;
    }
    
    function setFreezeProxy(address proxy) public restrictToOwner {
        freezeProxy = proxy;
    }
    //anyone can trigger transfer from "from" to "to" as long as allowance has been set to the SimpleTransfer contract
    function transferFromTo(address token, address from, address to, uint amount) public{
        require(ERC20Interface(token).allowance(from, address(this))>=amount);
        //check if for this address subscription is valid and if address is subscribed to the token it is checking
        if(freezeProxy!=address(0))
            //check if MonitorChain returns an error for that token, different values can be used, like lower than 2
            require(!Proxy(freezeProxy).freeze(token));
        //if monitorChain does not return an error for the token or the current smart contract is not subscribed properly, execute the transaction
        ERC20Interface(token).transferFrom(from,to,amount);
    }
}

contract Proxy{
    function freeze(address token) view public returns(bool);
}

contract MonitorChainProxy is Proxy{
    //user is the contract that is calling the proxy
    address private user;
    address private owner;
    address private monitorChain;
    function MonitorChainProxy(address userAddress){
        owner = msg.sender;
        user = userAddress;
    }
    
    function setUser(address userAddress) public restrictToOwner {
        require(userAddress!=address(0));
        user = userAddress;
    }
    
    modifier restrictToOwner(){
        require(msg.sender == owner);
        _;
    }
    
    modifier restrictToUser(){
        require(msg.sender == user);
        _;
    }
    
    function setMonitorChainAddress(address mcnAddress) public restrictToOwner {
        require(mcnAddress!=address(0));
        monitorChain = mcnAddress;
    }
    //important to add restriction modifier so MonitorChain data does not leak without subscription through the proxy to others
    function freeze(address token) view public restrictToUser returns(bool){
        if(monitorChain!=address(0) && AccessInterface(monitorChain).subscriptionIsValidForAccessAddress() && AccessInterface(monitorChain).canAccessToken(token))
            return AccessInterface(monitorChain).getStatusLevel(token) > 0;
        return false;
    }
}

contract AccessInterface {
    function minDays() public view returns(uint8 minDays);
    function pricePerTokenPerDay() public view returns(uint8 pricePerTokenPerDay);
    function priceForAllPerDay() public view returns(uint8 priceForAllPerDay);

    function getTokenForEventId(uint16 eventId) public view returns (address tokenAddress);
    function getTotalStatusCounts(address tokenAddress) view public returns (uint16 errorsCount);
    function getStatusLevel(address tokenAddress) view public returns (uint8 errorLevel);
    function getCurrentStatusDetails(address tokenAddress) view public returns (
        uint8, // errorLevel,
        string, // errorMessage,
        address, // setter,
        uint); // timestamp);

    function getStatusDetails(address tokenAddress, uint16 statusNumber) view public returns (
        uint8, // errorLevel,
        string, // errorMessage,
        address, // setter,
        uint, // timestamp,
        bool); // invalid);

    function getLastStatusDetails(address tokenAddress) view public returns (
        uint8, // errorLevel,
        string, // errorMessage,
        address, // setter,
        uint, // timestamp,
        bool); // invalid);


    function subscriptionIsValid() public view returns(bool isValid);
    function subscriptionIsValidForAccessAddress() view public returns(bool isValid);
    function isExistingSubscriber() public view returns (bool isSubscriber);
    function isSubscribedToToken(address token) public view returns (bool isSubscribed);
    function canAccessToken(address token) public view returns (bool canAccess);
    function getNumberSupportedTokens() public view returns (uint numberOfTokens);
    function getAllSupportedTokens() public view returns (address[] allTokens);

    function remainingSubscriptionDays() public view returns (uint remainingDays);
    function unsubscribe() public;

    function calculatePrice(uint numberOfDays, uint numberTokens) view public returns (
        uint, // priceToPay,
        uint, // averageDailyPrice,
        uint); // remainingOverheadBalance);

    function subscribe(address subscribee, uint numberOfDays, address[] tokenAddresses) public payable;
    function subscribeAll(address subscribee, uint numberOfDays) public payable;

    function getSubscriptionData() public view returns (
        uint, // start,
        uint, // numberOfDays,
        uint, // dailyPrice,
        uint, // overheadBalance,
        address); // accessAddress);
    
    function isAddressBlocked(address token, address addressToCheck) view public returns(bool);

    event TokenStatusChanged(uint16 eventId);
}

contract ERC20Interface {
    function symbol() public view returns(string);
    function name() public view returns(string);
    function version() public view returns(string);
    function decimals() public view returns(uint);
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
