pragma solidity ^0.4.21;

contract SimpleTransfer {
    address public owner;
    address private monitorChain;
    function SimpleTransfer(){
        owner = msg.sender;
    }
    
    modifier restrictToOwner(){
        require(msg.sender == owner);
        _;
    }
    
    function setMonitorChainAddress(address mcnAddress) public restrictToOwner {
        monitorChain = mcnAddress;
    }
    //anyone can trigger transfer from "from" to "to" as long as allowance has been set to the SimpleTransfer contract
    function transferFromToBlocking(address token, address from, address to, uint amount) public{
        require(ERC20Interface(token).allowance(from, address(this))>=amount);
        //check if for this address subscription is valid and if address is subscribed to the token it is checking
        if(monitorChain!=address(0) && AccessInterface(monitorChain).subscriptionIsValidForAccessAddress() && AccessInterface(monitorChain).canAccessToken(token))
            //check if MonitorChain returns an error for that token, different values can be used, like lower than 2
            require(AccessInterface(monitorChain).getStatusLevel(token) == 0);
        //if monitorChain does not return an error for the token or the current smart contract is not subscribed properly, execute transfer
        ERC20Interface(token).transferFrom(from,to,amount);
    }
    //if this function is to be called by some other smart contract
    function transferFromToWithResult(address token, address from, address to, uint amount) public returns(bool){
        if(ERC20Interface(token).allowance(from, address(this))>=amount)
            return false;
        //check if for this address subscription is valid and if address is subscribed to the token it is checking
        if(monitorChain!=address(0) && AccessInterface(monitorChain).subscriptionIsValidForAccessAddress() && AccessInterface(monitorChain).canAccessToken(token))
            //check if MonitorChain returns an error for that token, different values can be used, like greater than 2
            if(AccessInterface(monitorChain).getStatusLevel(token) > 0)
            //return false if monitorChain returns an error
                return false;
        //if monitorChain does not return an error for the token or the current smart contract is not subscribed properly, execute the transaction and return its transferFromToWithResult
        //be aware that some implementation of transferFrom do not necessarily return result, IDEX had this bug relying to this value
        return ERC20Interface(token).transferFrom(from,to,amount);
    }
    
    //try to conciel the return values from MonitorChain so the tokens statuses are not easily leaked through the public functions
    function getErrorReason(address token, address from, address to, uint amount) public returns(string){
        string memory error = "";
        //check if proper allowance has been set for this contract on the token contract
        if(ERC20Interface(token).allowance(from, address(this))>=amount){
            error = "Allowance not set";
            return(error);
        }
        //check if MonitorChain address has been properly set
        if(monitorChain==address(0)){
            error = "MonitorChain address not set";
            return(error);
        }
        //check if MonitorChain subscription is valid
        if(!AccessInterface(monitorChain).subscriptionIsValidForAccessAddress()){
            error = "MonitorChain subscription is not valid";
            return(error);
        }
        //check if this contract (its address) is subscribed as access address on MonitorChain for this token
        if(!AccessInterface(monitorChain).canAccessToken(token)){
            error = "Contract is not subscribed to this token on MonitorChain";
            return(error);
        }
        //check if MonitorChain returns an error for that token
        if(AccessInterface(monitorChain).getStatusLevel(token) > 0){
            //get the error for the token
            uint8 tokenStatus;
            address setter;
            uint timestamp;
            (tokenStatus, error, setter, timestamp) = AccessInterface(monitorChain).getCurrentStatusDetails(token);
            return(error);
        }
        //transfer method does not execute for some reason (might be strange token transferFrom implementation like with IDEX bug)
        error = "TransferFrom method errored";
        return(error);
    }
    
    //anyone can trigger transfer from "from" to "to" as long as allowance has been set to the SimpleTransfer contract
    //from address should be checked if it is being blocked
    function transferFromToAddressBlocking(address token, address from, address to, uint amount) public{
        require(ERC20Interface(token).allowance(from, address(this))>=amount);
        //check if for this address subscription is valid and if address is subscribed to the token it is checking
        if(monitorChain!=address(0) && AccessInterface(monitorChain).subscriptionIsValidForAccessAddress() && AccessInterface(monitorChain).canAccessToken(token))
            //check if MonitorChain has blocked the address that is participating in the trasfer
            require(!AccessInterface(monitorChain).isAddressBlocked(token, from));
        //if monitorChain has not blocked the from address for the token or the current smart contract is not subscribed properly, execute transfer
        ERC20Interface(token).transferFrom(from,to,amount);
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
