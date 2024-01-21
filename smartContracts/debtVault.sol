//SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface wethPool
{
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
    function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf) external;
}

contract debtVault is ERC721
{
    struct delegationData
    {
        uint256 delegationId;
        address delegator;
        address delegatee;
        uint256 delegationTimestamp;
    }

    struct debtData
    {
        uint256 creditId;
        string offChainLegalAgreement;
        address creditDelegator;
        address creditDelegatee;
        uint256 creditValue;
        uint256 percentageFee;
        uint256 totalDebt;
        uint256 debtTimestamp;
    }

    address public owner;
    uint256 public counter = 0;

    mapping(uint256 => delegationData) public delegationInfo;
    mapping(uint256 => debtData) public debtsInfo;
    mapping(address => debtData[]) public creditDelegations;
    mapping(address => debtData[]) public debts;
    mapping(address => uint) public totalPendingDebt;
    mapping(uint256 => bool) public debtIsActive;



    constructor() ERC721("debtNfts", "debtNfts")
    {
        owner = msg.sender;
    }

    function setDelegationData(address paramDelegator, address paramDelegatee) public returns(uint256)
    {
        require(msg.sender == owner,  "Caller is not ghoInvestmentVault.");

        counter++;
        delegationData memory newDelegation = delegationData(counter, paramDelegator, paramDelegatee, block.timestamp);
        delegationInfo[counter] = newDelegation;

        return counter;
    }

    function borrowAndTransferAgreedValueToDelegatee(uint256 paramId, string memory paramOffChainLegalAgreement, uint256 paramCreditValue, uint256 paramPercentageFee) public
    {
        require(msg.sender == owner, "Caller is not ghoInvestmentVault.");
        require(paramPercentageFee > 0, "Percentage cant be zero.");

        delegationData memory info = delegationInfo[paramId];
        uint256 totalDebt = (paramCreditValue * paramPercentageFee) / 100;
        debtData memory newDebt = debtData(paramId, paramOffChainLegalAgreement, info.delegator, info.delegatee, paramCreditValue, paramPercentageFee, totalDebt, block.timestamp);
        
        debtsInfo[paramId] = newDebt;
        creditDelegations[info.delegator].push(newDebt);
        debts[info.delegatee].push(newDebt);
        totalPendingDebt[info.delegatee] += totalDebt;
        debtIsActive[paramId] = true;

        wethPool(0xcC6114B983E4Ed2737E9BD3961c9924e6216c704).borrow(0xc199807AF4fEDB02EE567Ed0FeB814A077de4802, paramCreditValue, 2, 0, msg.sender);

        _safeMint(info.delegatee, counter);
    }

    function getDebtVaultAddress() public view returns(address)
    {
        return address(this);
    }
}