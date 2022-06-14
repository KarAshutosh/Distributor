// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
import "./managers.sol";



contract Deposit is Managers 
{    
    uint deployDate;
    //address[] storage token;  // for dynamic arrays   
    address[] token;        // for static arrays (preferred)
    uint8 public tokenTypes = 0;
    

    function addToken(address _token) public onlyOwnerAndManager
    {
        token[tokenTypes] = _token;
        tokenTypes = tokenTypes + 1;
    }

    function removeTokenByID(uint8 _tokenID) public onlyOwnerAndManager
    {
        
        uint lastToken = tokenTypes - 1;
        //oldTokenID = _tokenID
        token[_tokenID] = token[lastToken];
        token.pop();
        tokenTypes = tokenTypes - 1;
    }

    /*

    function removeTokenByAddress(address _token) public onlyOwnerAndManager
    {
        for(uint8 i = 0; i < tokenTypes; i++)
        {
            if(token[i] == _token)
            {
                uint8 lastToken = tokenTypes - 1;
                //address oldToken = token[i];
                token[i] = token[lastToken];
                tokenTypes = tokenTypes - 1;
                break;
            }
        }
    }

    */    

    //returns an address to use with IERC20
    function getTokenAddressByID(uint8 _tokenID) public view returns (address) 
    {
        address _tokenAddress = token[_tokenID];
        return _tokenAddress;
    } 

    //Send funds to smart contract
    function deposit(uint _amount, uint8 _tokenID) public payable 
    {
        // Set the minimum amount to 0.01 token (for GAMMA)
        uint _minAmount = 0.01*(10**18);
        require(_amount >= _minAmount, "Amount less than minimum amount");  
        IERC20(getTokenAddressByID(_tokenID)).transferFrom(msg.sender, address(this), _amount);
    }

    //See present funds in smart contract
    function getContractBalanceByID(uint8 _tokenID) public onlyOwnerAndManager view returns(uint)
    {
        return IERC20(getTokenAddressByID(_tokenID)).balanceOf(address(this));
    }    

    
    
}
