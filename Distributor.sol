// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Distributor is Ownable
{
    event Authorized(address,bool);
    event AuthorizationToggled(address, bool, bool);
    event DistributionFrozen(bool);
    event TokenAdded(address);
    event TokenRemoved(address);
    event ReceiverUpdate(address, uint, uint, uint, bool);
    event DistributionOn(uint);
    event balanceInsufficient(address, uint);
    event PassedCheck(address, bool);

    constructor()
    {
        lastDistribution = block.timestamp;   
    }

    uint lastDistribution;

    modifier onlyWeekly 
    {
      require(block.timestamp > lastDistribution + 604740);
      _;
    }

    bool recieverEditable = true;

    modifier editProtection 
    {
      require(recieverEditable == true);
      _;
    }

    mapping(address => bool) public authorized;
    
    function addAuthorizedAddress(address _user) external onlyOwner 
    {
        require(_user != address(0),"_user should not be zero address");
        authorized[_user] = true;
        emit Authorized(_user, true);        
    }

    function updateAuthorizedAddress(address _user) external onlyOwner 
    {
        require(_user != address(0),"_user should no be zero address");
        bool prev = authorized[_user];
        authorized[_user] = !prev;
        emit AuthorizationToggled(_user, prev, !prev);
    }

    modifier onlyAuthorized 
    {
        require(authorized[_msgSender()] == true, "only authorized user is allowed");
        _;
    }

    bool internal frozenVal = false;

    modifier checkFrozen
    {
        require(frozenVal == false, "Tranzactions have been frozen");
        _;
    }

    function freezeSending() external onlyOwner returns(bool)
    {
        frozenVal = true;
        emit DistributionFrozen(true);
        return frozenVal;
    }

    function unfreezeSending() external onlyOwner returns(bool)
    {
        frozenVal = false;
        emit DistributionFrozen(false);
        return frozenVal;
    }

    address[] public token;        
    uint public tokenTypes = 0;
    //uint public token.length();
    
    function addToken(address _token) external onlyAuthorized editProtection
    {
        token[tokenTypes] = _token;
        tokenTypes = tokenTypes + 1;
        emit TokenAdded(_token);
    }

    function removeToken(uint _tokenID) external onlyAuthorized editProtection
    {
        
        uint lastToken = tokenTypes - 1;
        address oldToken = token[_tokenID];
        token[_tokenID] = token[lastToken];
        token.pop();
        tokenTypes = tokenTypes - 1;
        emit TokenRemoved(oldToken);
    }

    //Use this to cross check if the right token is being removed in removedStabes
    function getTokenAddressByID(uint _tokenID) public view returns (address) 
    {
        address tokenAdd = token[_tokenID];
        return tokenAdd;
    } 

    //Send funds to smart contract  
    function deposit(uint _amount, uint _tokenID) public payable 
    {  
        IERC20(getTokenAddressByID(_tokenID)).transferFrom(msg.sender, address(this), _amount);
    }

    //See present funds in smart contract
    function getBalanceByID(uint _tokenID) public view returns(uint)
    {
        return IERC20(getTokenAddressByID(_tokenID)).balanceOf(address(this));
    } 

    struct receiverStruct
    { 
        address receiverAdd;
        uint distributionID;
        uint tokenID;
        uint receiveAmt;
        bool willReceive;
    }

    uint totalDistributions = 0;

    receiverStruct[] public receiverList;
    uint[] public balanceNeeded;

    function AddReceiver(address _receiverAdd, uint _tokenID, uint _receiveAmt) external onlyAuthorized editProtection
    {
        receiverList[totalDistributions] = receiverStruct(_receiverAdd, totalDistributions, _tokenID, _receiveAmt, true);
        emit ReceiverUpdate(_receiverAdd, totalDistributions, _tokenID, _receiveAmt, true);
        totalDistributions = totalDistributions + 1;
        balanceNeeded[_tokenID] = balanceNeeded[_tokenID] + _receiveAmt;
        
    }

    function UpdateReceiver(address _receiverAdd, uint _distributionID, uint _tokenID, uint _receiveAmt, bool _willReceive) external onlyAuthorized editProtection
    {
        uint previousAmt = receiverList[_distributionID].receiveAmt;
        balanceNeeded[_tokenID] = balanceNeeded[_tokenID] - previousAmt;  
        
        receiverList[_distributionID] = receiverStruct(_receiverAdd, _distributionID, _tokenID, _receiveAmt, _willReceive);
        emit ReceiverUpdate(_receiverAdd, _distributionID, _tokenID, _receiveAmt, _willReceive);
        
        balanceNeeded[_tokenID] = balanceNeeded[_tokenID] + _receiveAmt;
    }

    bool internal balanceSufficient = false;

    function checkSufficient() public onlyAuthorized 
    {
        uint checkFails = 0;

        for(uint _tokenID = 0; _tokenID < tokenTypes; _tokenID++)
        {
            uint currentBalance = getBalanceByID(_tokenID);
            uint neededBalance = balanceNeeded[_tokenID];
            address theToken = token[_tokenID];

            if(neededBalance > currentBalance)
            {
                checkFails = checkFails + 1;

                uint missingBalance = neededBalance - currentBalance;

                emit PassedCheck(theToken, false);
                emit balanceInsufficient(theToken, missingBalance);

            }
            
            //balanceSufficient = true; 
            else
            {
                emit PassedCheck(theToken, true);
            }
                    
            
        }

        if(checkFails > 0)
        {
            balanceSufficient = false;
        }

        if(checkFails == 0)
        {
            balanceSufficient = true;
            recieverEditable = false;
        }

    }

    function refreshCheck() external onlyAuthorized
    {
        balanceSufficient = false;
        recieverEditable = true;
    }
        
    function distributeToAll() external payable onlyAuthorized onlyWeekly
    {
        require(balanceSufficient == true, "Insufficient balance");

        for(uint i = 0; i < totalDistributions; i++)
        {
            IERC20(getTokenAddressByID(receiverList[i].tokenID)).transferFrom(address(this), receiverList[i].receiverAdd, receiverList[i].receiveAmt);
        }

        balanceSufficient = false;
        lastDistribution = block.timestamp;
        emit DistributionOn(lastDistribution);
    }   
    
}
