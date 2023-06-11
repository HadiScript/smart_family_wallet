//SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

contract consumer {
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function deposite() public payable {}
}

contract familyWallet {
    address payable public owner;

    // we givving permission to some to send specific money
    // like 0x232131 -> 50 wie
    mapping(address => uint256) allowance;
    mapping(address => bool) isAllowedToSent;

    mapping(address => bool) guardians;

    address payable nextOwner;
    uint256 guardiansResetCounts;
    uint256 public constant confirmationFromGuardiansForReset = 3;
    mapping(address => mapping(address => bool)) nextOwnerGuardianBool;

    function purposeNewOwner(address payable _newOwner) public {
        require(guardians[msg.sender], "you are not a owner");

        require(
            nextOwnerGuardianBool[_newOwner][msg.sender] == false,
            "you are already voted"
        );

        if (_newOwner != nextOwner) {
            nextOwner = _newOwner;
            guardiansResetCounts = 0;
        }
        guardiansResetCounts++;

        if (guardiansResetCounts >= confirmationFromGuardiansForReset) {
            owner = nextOwner;
            nextOwner = payable(address(0));
        }
    }

    constructor() {
        owner = payable(msg.sender);
    }

    function setGuardiance(address _address, bool isYes) public {
        require(owner == msg.sender, "sorry you are not a owner");
        guardians[_address] = isYes;
    }

    function setAllowance(address _to, uint256 _amount) public {
        require(owner == msg.sender, "sorry you are not a owner");

        allowance[_to] = _amount;
        if (allowance[_to] > 0) {
            isAllowedToSent[_to] = true;
        } else {
            isAllowedToSent[_to] = false;
        }
    }

    // transfer money to any one -> can send to a person, can send to any contract
    function transfer(
        address payable _to,
        uint256 _amount,
        bytes memory _payload
    ) public returns (bytes memory) {
        // require(owner == msg.sender, "your are not a owner");

        if (owner != msg.sender) {
            require(
                allowance[msg.sender] >= _amount,
                "you are sending more money than you are allowed to"
            );
            require(isAllowedToSent[msg.sender], "you are not allowed");

            allowance[msg.sender] -= _amount;
        }

        (bool success, bytes memory returnData) = _to.call{value: _amount}(
            _payload
        );

        require(success, "Transection failed");
        return returnData;
    }

    // our contract can receive fund
    receive() external payable {}
}
