// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";

contract Distributor is Ownable
{
    /*
    constructor(address gammaAdd) public
    {
        
        addToken(gammaAdd);
    }
    */

    mapping(address => bool) public authorized;
    
    function addAuthorizedAddress(address _user) external onlyOwner 
    {
        require(_user != address(0),"_user should not be zero address");
        authorized[_user] = true;
        //emit Authorized(_user, true);        
    }

    function updateAuthorizedAddress(address _user) external onlyOwner 
    {
        require(_user != address(0),"_user should no be zero address");
        bool prev = authorized[_user];
        authorized[_user] = !prev;
        //emit AuthorizationToggled(_user, prev, !prev);
    }

    modifier onlyAuthorized() 
    {
        require(authorized[_msgSender()] == true, "only authorized user is allowed");
        _;
    }

    bool frozenVal = false;

    modifier checkFrozen()
    {
        require(frozenVal == false, "Tranzactions have been frozen");
        _;
    }

    function freezeSending() external onlyOwner returns(bool)
    {
        frozenVal = true;
        return frozenVal;
    }

    function unfreezeSending() external onlyOwner returns(bool)
    {
        frozenVal = false;
        return frozenVal;
    }

    address[] public token;        
    uint public tokenTypes = 0;
    //uint public token.length();
    
    function addToken(address _token) external onlyAuthorized
    {
        token[tokenTypes] = _token;
        tokenTypes = tokenTypes + 1;
        //emit newStableCoin(_token);
    }

    //Use this to cross check if the right token is being removed in removedStabes
    /*
    function getTokenAddressByID(uint _tokenID) external view onlyAuthorized returns(address)
    {
        address tokenAdd = token[_tokenID];
        return tokenAdd;    
    }
    */

    function removeToken(uint _tokenID) external onlyAuthorized
    {
        
        uint lastToken = tokenTypes - 1;
        //oldToken = token[_tokenID];
        token[_tokenID] = token[lastToken];
        token.pop();
        tokenTypes = tokenTypes - 1;
        //emit removedStableCoin(oldToken);
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
        uint _minAmount = 0.01*(10**18);
        require(_amount >= _minAmount, "Amount less than minimum amount");  
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

    function AddReceiver(address _user, uint _tokenID, uint _amt) external onlyAuthorized
    {
        receiverList[totalDistributions] = receiverStruct(_user, totalDistributions, _tokenID, _amt, true);
        totalDistributions = totalDistributions + 1;
    }

    
    //cross checking
    /*
    function receiverInfoByID(uint distributionID) public view returns (address, uint256, uint256, bool) 
    {
        address _receiverAdd = receiverList[distributionID].receiverAdd;
        uint256 _tokenID = receiverList[distributionID].tokenID;
        uint256 _receiveAmt = receiverList[distributionID].receiveAmt;
        bool _willReceive = receiverList[distributionID].willReceive;
        address _receiverAdd = receiverList[distributionID].receiverAdd;
        uint256 _tokenID = receiverList[distributionID].tokenID;
        uint256 _receiveAmt = receiverList[distributionID].receiveAmt;
        bool _willReceive = receiverList[distributionID].willReceive;

        
        return (_receiveAmt, _tokenID, _receiveAmt, _willReceive);
    }*/

    function UpdateReceiver(address _receiverAdd, uint _distributionID, uint _tokenID, uint _receiveAmt, bool _willReceive) external onlyAuthorized
    {
        receiverList[_distributionID] = receiverStruct(_receiverAdd, _distributionID, _tokenID, _receiveAmt, _willReceive);
    }

    bool balanceSufficient = false;


    function checkSufficient() public onlyAuthorized returns(string memory)
    {
        uint[] memory balanceCheck;
        uint[] memory balanceNeeded; 

        for(uint _tokenID = 0; _tokenID < tokenTypes; _tokenID++)
        { 
            
            for(uint j = 0; j < totalDistributions; j++)
            {
                uint currentAmount = receiverList[j].receiveAmt;
                uint currentTokenID = receiverList[j].tokenID;
                balanceNeeded[currentTokenID] = balanceNeeded[currentTokenID] + currentAmount;
            }     
            
            balanceCheck[_tokenID] = getBalanceByID(_tokenID);
            
            if(balanceCheck[_tokenID] >= balanceNeeded[_tokenID])
            {
                balanceSufficient = true;
                
            }

            //address tokenAddress = getTokenAddressByID(_tokenID);

            else
            {
                return "Insufficient funds in contract";
            }
        
        }

        return "Balance Sufficient";

        

       

    }

    function distributeToAll() external onlyAuthorized
    {
        for(uint i = 0; i < totalDistributions; i++)
        {
            IERC20(getTokenAddressByID(receiverList[i].tokenID)).transferFrom(address(this), receiverList[i].receiverAdd, receiverList[i].receiveAmt);
        }
    } 

    
    
}









