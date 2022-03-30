// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

/**
I am trying to implement a banking system on blockchain with Solidity. The features are basic and simple
 Features:
 -> The address who deployed the contract(Contract owner) is seen as the owner of the bank
 -> Owner of the bank can create account for the customers of the bank or delete them
 -> Customers of the bank can deposit funds to their account and add or remove beneficiaries (not necessarily customers) to their account
 -> These so called beneficaries are allowed to withdraw from the account of their benefactors an amount not greater than a certain amount set by the benefactor who is a customer of the bank
 -> 
 
 */

contract MiniBank {
    address owner;

    constructor() {
        owner = msg.sender;
        account[owner].haveAccount = true;
    }

    struct AccountDetails {
        uint256 balance;
        mapping(address => uint256) allowance;
        bool haveAccount;
    }

    mapping(address => AccountDetails) public account;

    event Deposit(address _to, uint256 amount);
    event Withdraw(address _to, uint256 amount);
    event UpdateAccountMaxAmountToBeneficiaries(uint256 amount);

    modifier onlyOwner() {
        require(
            owner == msg.sender,
            "You are not allowed to perform this action"
        );
        _;
    }

    modifier verifyAccountExists() {
        require(account[msg.sender].haveAccount, "This account does not exist");
        _;
    }

    modifier closeAccountPermission(address customer) {
        require(
            owner == msg.sender || msg.sender == customer,
            "You are not allowed to perform this action"
        );
        _;
    }

    modifier accountAlreadyExists(address newCustomer) {
        require(
            !account[newCustomer].haveAccount,
            "Customer already has an account"
        );
        _;
    }

    function createAccount(address newCustomer)
        public
        onlyOwner
        accountAlreadyExists(newCustomer)
    {
        account[newCustomer].haveAccount = true;
    }

    function closeAccount(address customer)
        public
        verifyAccountExists
        closeAccountPermission(customer)
    {
        account[customer].haveAccount = false;
    }

    function convertEth2Wei(uint256 amountInEther)
        public
        pure
        returns (uint256)
    {
        return amountInEther * 1 ether;
    }

    function withdraw(uint256 amountInEther) public verifyAccountExists {
        require(
            account[msg.sender].balance >= this.convertEth2Wei(amountInEther),
            "You cannot withdraw more than your balance"
        );
        account[msg.sender].balance -= this.convertEth2Wei(amountInEther);
        emit Withdraw(msg.sender, this.convertEth2Wei(amountInEther));
        payable(msg.sender).transfer(this.convertEth2Wei(amountInEther));
    }

    function fetchBenficaryBalance(address benefactor)
        public
        view
        returns (uint256)
    {
        return account[benefactor].allowance[msg.sender];
    }

    function beneficiaryWithdrawal(uint256 amountInEther, address benefactor)
        public
    {
        require(
            account[benefactor].allowance[msg.sender] > amountInEther,
            "Threshold balance reached"
        );
        require(
            account[benefactor].balance > amountInEther,
            "Balance in the account is too low for this withdrawal"
        );
        account[benefactor].balance -= this.convertEth2Wei(amountInEther);
        account[benefactor].allowance[msg.sender] -= this.convertEth2Wei(
            amountInEther
        );
        emit Withdraw(msg.sender, this.convertEth2Wei(amountInEther));
        payable(msg.sender).transfer(this.convertEth2Wei(amountInEther));
    }

    function setBeneficiaryAllowance(
        uint256 maxAmountToWithdrawInEther,
        address beneficiary
    ) public verifyAccountExists {
        account[msg.sender].allowance[beneficiary] += this.convertEth2Wei(
            maxAmountToWithdrawInEther
        );
        emit UpdateAccountMaxAmountToBeneficiaries(
            this.convertEth2Wei(maxAmountToWithdrawInEther)
        );
    }

    receive() external payable verifyAccountExists {
        account[msg.sender].balance += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
}
