//SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./interfaces/AggregatorV3Interface.sol";
import {GhoToken} from "../gho-core/src/contracts/gho/GhoToken.sol";
import {debtVault} from "./debtVault.sol";
import {ccipGhoToken} from "./ccipGhoToken.sol";

interface WrappedTokenGatewayV3
{
    function depositETH(address, address onBehalfOf, uint16 referralCode) external payable;
}

interface wEth
{
    function deposit() external payable;
}

interface wethPool
{
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
    function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf) external;
}

interface ICreditDelegationToken 
{
  /**
   * @dev Emitted on `approveDelegation` and `borrowAllowance
   * @param fromUser The address of the delegator
   * @param toUser The address of the delegatee
   * @param asset The address of the delegated asset
   * @param amount The amount being delegated
   */
  event BorrowAllowanceDelegated(
    address indexed fromUser,
    address indexed toUser,
    address indexed asset,
    uint256 amount
  );

  /**
   * @notice Delegates borrowing power to a user on the specific debt token.
   * Delegation will still respect the liquidation constraints (even if delegated, a
   * delegatee cannot force a delegator HF to go below 1)
   * @param delegatee The address receiving the delegated borrowing power
   * @param amount The maximum amount being delegated.
   */
  function approveDelegation(address delegatee, uint256 amount) external;

  /**
   * @notice Returns the borrow allowance of the user
   * @param fromUser The user to giving allowance
   * @param toUser The user to give allowance to
   * @return The current allowance of `toUser`
   */
  function borrowAllowance(address fromUser, address toUser) external view returns (uint256);

  /**
   * @notice Delegates borrowing power to a user on the specific debt token via ERC712 signature
   * @param delegator The delegator of the credit
   * @param delegatee The delegatee that can use the credit
   * @param value The amount to be delegated
   * @param deadline The deadline timestamp, type(uint256).max for max deadline
   * @param v The V signature param
   * @param s The S signature param
   * @param r The R signature param
   */
  function delegationWithSig(
    address delegator,
    address delegatee,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}

interface flashloanCallback
{
    function recoverFlashloan() external;
} 

contract ghoInvestmentVault is ERC721
{
    event investment(string msg, investmentStruct investment);
    event ghoBalanceRetrieved(string msg, address investor, uint256 amountTransfered, uint256 balanceBefore, uint256 balanceAfter);

    struct investmentStruct
    {
        uint investmentId;
        address investor;
        uint quantityOf10CentsOfEther;
        uint etherPriceInUsd;
        uint orderTotalInUsd;
        uint ghoAcquired;
    }


    address public owner;
    uint256 public counter = 0;
    uint256 flashloanCollectedGhoFee = 0;

    AggregatorV3Interface internal goerliTestnetEtherPrice;
    GhoToken internal ghoTokenInstance;
    debtVault internal debtVaultInstance;


    mapping(uint => investmentStruct ) public investmentNftsData;
    mapping(address => uint) public investorsGhoBalance;
    mapping(address => uint) public investorsAaveV3Credit;
    mapping(address => uint) public pointsToUse;



    constructor() ERC721("investmentNfts", "invNfts")
    {
        goerliTestnetEtherPrice = AggregatorV3Interface(0x0715A7794a1dc8e42615F059dD6e406A6594651A);
        owner = msg.sender;

        ghoTokenInstance = new ccipGhoToken();
        debtVaultInstance = new debtVault();
    }

    
    function getEthUsd() public view returns (int) 
    {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = goerliTestnetEtherPrice.latestRoundData();

        return price;
    }

    function invest(uint256 paramQuantity) public payable
    {
        uint investmentQuantityInWei = paramQuantity * 0.1 ether;

        require(msg.value >= investmentQuantityInWei, "Not enough ether send.");

        uint etherPrice = uint(getEthUsd()) * (10 ** 10);
        uint userSentTotalInUsd = etherPrice * paramQuantity;

        counter++;
        _safeMint(msg.sender, counter);


        uint overColateral = investmentQuantityInWei / 3;
        uint ghoToMint = ((overColateral * 2) * etherPrice) / (1 ether);

        ghoTokenInstance.mint(address(this), ghoToMint);

        investmentStruct memory newNftData = investmentStruct(counter, msg.sender, msg.value, etherPrice, (etherPrice * msg.value), ghoToMint);
        investmentNftsData[counter] = newNftData;

        investorsGhoBalance[msg.sender] = ghoToMint;

        emit investment("investmentDone", newNftData);


        WrappedTokenGatewayV3(0x8dA9412AbB78db20d0B496573D9066C474eA21B8).depositETH{value: msg.value}(address(0), address(this), 0);

        investorsAaveV3Credit[msg.sender] = msg.value;
    }

    function buyPointsWithEther(uint256 paramQuantity, address paramBuyer) public payable
    {
        require(msg.value >= paramQuantity * 0.001 ether);

        for(uint i = 0; i < paramQuantity;i++)
        {
            counter++;
            _safeMint(paramBuyer, counter);
        }

        pointsToUse[paramBuyer] += paramQuantity * 0.001 ether;
    }

    function investWithPoints(uint256 paramQuantity) public
    {
        require(pointsToUse[msg.sender] >= paramQuantity, "Not enough points.");

        pointsToUse[msg.sender] -= paramQuantity;
        uint overColateral = paramQuantity / 3;
        uint etherPrice = uint(getEthUsd()) * (10 ** 10);
        uint ghoToMint = ((overColateral * 2) * etherPrice) / (1 ether);

        ghoTokenInstance.mint(address(this), ghoToMint);

        investmentStruct memory newNftData = investmentStruct(counter, msg.sender, paramQuantity, etherPrice, (etherPrice * paramQuantity), ghoToMint);
        investmentNftsData[counter] = newNftData;

        investorsGhoBalance[msg.sender] = ghoToMint;

        emit investment("investmentDone", newNftData);


        WrappedTokenGatewayV3(0x8dA9412AbB78db20d0B496573D9066C474eA21B8).depositETH{value: paramQuantity}(address(0), address(this), 0);

        investorsAaveV3Credit[msg.sender] = paramQuantity;
    }

    function retrieveWethFromAavePool(uint256 paramAmount) public
    {
        require(paramAmount <= investorsAaveV3Credit[msg.sender], "Exceed quantity of reserves to withdraw.");
        wethPool(0xcC6114B983E4Ed2737E9BD3961c9924e6216c704).withdraw(0xaD3C5a67275dE4b5554CdD1d961e957f408eF75a, paramAmount, msg.sender);
    }

    function makeCreditDelegation(address paramDelegatee ,uint256 paramAmount, string memory paramOffChainLegalAgreement, uint256 paramPercentageFee) public
    {
        require(paramAmount <= investorsAaveV3Credit[msg.sender], "Exceed quantity of reserves to withdraw.");

        address debtVaultAddress = debtVaultInstance.getDebtVaultAddress();
        ICreditDelegationToken(0x6B9f12aD327e2760816A8a6c7A740AeA901fEB21).approveDelegation(debtVaultAddress, paramAmount);
        uint256 actualId = debtVaultInstance.setDelegationData(msg.sender, paramDelegatee);
        
        debtVaultInstance.borrowAndTransferAgreedValueToDelegatee(actualId, paramOffChainLegalAgreement, paramAmount, paramPercentageFee);
    }

    function investorRetrieveGhoToken(uint256 paramAmountToRetrieve) public
    {
        uint256 balance = investorsGhoBalance[msg.sender];
        uint256 permittedAmount = balance / 3;
        permittedAmount = permittedAmount * 2;

        require(investorsGhoBalance[msg.sender] > paramAmountToRetrieve, "notEnoughBalance.");
        require(permittedAmount >= paramAmountToRetrieve, "notEnoughBalance.");

        uint256 balanceBefore = investorsGhoBalance[msg.sender];
        investorsGhoBalance[msg.sender] -= paramAmountToRetrieve;
        uint256 balanceAfter = investorsGhoBalance[msg.sender];

        ghoTokenInstance.transfer(msg.sender, paramAmountToRetrieve);

        emit ghoBalanceRetrieved("Investor gho retrieved.", msg.sender, paramAmountToRetrieve, balanceBefore, balanceAfter);
    }

    function vaultGhoInPossession() public view returns(uint256)
    {
        return ghoTokenInstance.balanceOf(address(this));
    }

    function getGhoBalanceOfAddress(address paramAddress) public view returns(uint256)
    {
        return ghoTokenInstance.balanceOf(paramAddress);
    }

    function flashloan(uint256 paramAmount) public
    {
      uint256 vaultBalanceBefore = ghoTokenInstance.balanceOf(address(this));
      require(paramAmount <= vaultBalanceBefore, "Vault doesnt have enough GHO.");

      uint256 fee = vaultBalanceBefore / 10;

      ghoTokenInstance.transfer(msg.sender, paramAmount);
      flashloanCallback(msg.sender).recoverFlashloan();

      uint256 vaultBalanceAfter = ghoTokenInstance.balanceOf(address(this));
      require(vaultBalanceAfter >= (paramAmount + fee), "Flashloan liquidity not received back.");

      flashloanCollectedGhoFee += fee;
    }




    receive() external payable {}

    function claimEtherBack() public
    {
        require(msg.sender == owner, "notOwner.");

        uint balance = address(this).balance; 
        
        payable(owner).transfer(balance);
    }
}