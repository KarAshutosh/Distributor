// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Managers is Ownable
{
    address[] public managers;
    uint8 public managerCount = 0; 

    function addManager(address _newManager)  public onlyOwner
    {
        managers[managerCount] = _newManager;
        managerCount = managerCount + 1;
    }        

    /*
    function removeManagerByAddress(address _oldManager)  public onlyOwner
    {
        for(uint8 i = 0; i < managerCount; i++)
        {
            if(managers[i] == _oldManager)
            {
                uint8 lastManager = managerCount - 1;
                //address oldManager = managers[i];
                managers[i] = managers[lastManager];
                managerCount = managerCount - 1;
                break;
            }
        }
    }   
    */

    function removeManagerByID(uint8 _ManagerID) public onlyOwner
    {
        uint8 lastManager = managerCount - 1;
        //oldManagerID = _ManagerID
        managers[_ManagerID] = managers[lastManager];
        managers.pop();
        managerCount = managerCount - 1;
    }



    modifier onlyManagers
    {
        bool isManager = false;

        for(uint8 i = 0; i < managerCount; i++)
        {
            if(managers[i] == _msgSender())
            {
                isManager = true;
                break;
            }
        }

        require(isManager = true, "Wallet not authorised");
        _;
    }

    modifier onlyOwnerAndManager
    {
        bool isManager = false;

        for(uint8 i = 0; i < managerCount; i++)
        {
            if(owner() == _msgSender())
            {
                isManager = true;
                break;
            }

            if(managers[i] == _msgSender())
            {
                isManager = true;
                break;
            }
        }

        require(isManager = true, "Wallet not authorised");
        _;

    }
}
