//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

contract Consumer {
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function deposit() public payable {}
}

contract SmartWallet {

    address payable public owner;

    mapping(address => uint) public allowance;
    mapping(address => bool) public isAllowedToSend;

    mapping(address => bool) public guardians;
    address payable nextOwner;
    mapping(address => mapping(address => bool)) nextOwnerGuardianVotedBool;
    uint guardiansResetCount;
    uint public constant confirmationsFromGuardiansForReset = 3;

    modifier onlyOwner() {
        require(msg.sender == owner, "you are not the owner, aborting");
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    function setGardian(address _guardian, bool _isGuardian) public onlyOwner {
        guardians[_guardian] = _isGuardian;
    }

    function proposedNewOwner(address payable _newOwner) public {
        require(guardians[msg.sender], "You are not guardian of this wallet, aborting");
        require(nextOwnerGuardianVotedBool[_newOwner][msg.sender] == false, "You already voted, aborting");
        if (_newOwner != nextOwner) {
            nextOwner = _newOwner;
            guardiansResetCount = 0;
        }

        guardiansResetCount++;

        if (guardiansResetCount >= confirmationsFromGuardiansForReset) {
            owner = nextOwner;
            nextOwner = payable(address(0));
        }
    }

    function setAllowance(address _for, uint _amount) public onlyOwner {
        allowance[msg.sender] = _amount;

        if (_amount > 0) {
            isAllowedToSend[_for] = true;
        } else {
            isAllowedToSend[_for] = false;
        }
    }

    function transfer(address payable _to, uint _amount, bytes memory _payload) public returns(bytes memory) {
        //requires(msg.sender == owner, "You are not the owner, aborting");
        if (msg.sender != owner) {
            require(allowance[msg.sender] >= _amount, "You are trying to send more than you are allowed to, aborting");
        }

        (bool success, bytes memory returnData) = _to.call{value: _amount}(_payload);
        require(success, "Aborting, call was not successful");
        return returnData;
    }

    function balance() public view returns(uint) {
        return address(this).balance;
    }

    receive() external payable { }
}