# lfghoHackathon
//PLEASE READ FULL DESCRIPTION OF READ ME.//////////////////////////////////////////////////////

"./yieldGhoVault" project for lfghoHackathon.

We utilized Aave's pools to supply WETH and generate yield from it. Aave's credit delegation allows investors to make off-chain legal agreements to also gain yield from their borrowing power. A vault is used to design strategies and serves as a facilitator to manage the issuance of GHO, calculating the correct peg and its ratio. Account abstraction is employed to create a mailWallet to onboard Web2 investors, and CCIP's cross-chain infrastructure enables people to invest in other chains' DeFi protocols with the GHO stablecoin.

The ptrotocol offers 3 different yield revenues on the same provided asset as collateral for gho:
  - Supply collateral to aave
  - Lend borrwingPower of supplied collateral
  - Gho:
      - External yield generation on any crossChain deFi protocol
      - Vault fee from flashloans



The general flow and arquitecture is as follows:
  - emailBased abstractedAccounts are used to onboard web2 traditional investors so they dont have to go through the hassle of understanding the concept of gas, signing, etc.
  - ghoInvestmentVault to manage internally the investments collateral that go to suppluy aave´s pool. It also provides infrastructure to offer flashloans.
  - debtVault to manage the debt of offChain legalAgreements for lending the investors borrowingPower.
  - Aave protocol to generate yield.
  - CCIP to let the investor and borrower use their gho stablecoin on any external crossChain deFi protocol on any evmCompatibleChain.
<img width="690" alt="image" src="https://github.com/Kanoopz/lfghoHackathon/assets/43384993/1f560c51-b249-4638-a88f-4d1070b47807">


To simplify the onboarding experience to the web2 traditional users we implemented abstractedAccounts with emailAuthentication and a creditCard ramp to supply liquidity as collateral for issuing gho with fiat.
* EVEN THOUGH THE FOCUS IS ON WEB2 TRADITIONAL USER, THE PROTOCOL CAN BE INTERACTED WITH ANY WEB3 NATIVE WALLET (METAMASK, RABBIT, ETC.)
<img width="651" alt="image" src="https://github.com/Kanoopz/lfghoHackathon/assets/43384993/d8e9c4ec-d385-4e25-9fd0-308304fc7b96">

<img width="648" alt="image" src="https://github.com/Kanoopz/lfghoHackathon/assets/43384993/28ac137f-84c0-4ff7-9e58-4bcb5f632aa2">

<img width="422" alt="image" src="https://github.com/Kanoopz/lfghoHackathon/assets/43384993/8ca6b1ba-81c9-4b58-bec5-868f00ba1428">



The vault supplies the provided amount of collateral to the aaveProtocol and issues the gho stablecoin to a ratio of 1 GHO : 1.5 USD in value.
<img width="543" alt="image" src="https://github.com/Kanoopz/lfghoHackathon/assets/43384993/6b585adc-bc69-425a-9ab6-2f0285d083ee">

Once the investors collateral has been supplied to aave, if he reaches a legal agreement, he can apply the second type of yield: lending his borrowing power to a delegatee. This type of yield is done using the debtVault that manages all the logic and the process.
<img width="608" alt="image" src="https://github.com/Kanoopz/lfghoHackathon/assets/43384993/d3e05292-e16d-4af3-985e-cae19219de4f">

The last step is to use the issued gho to generate a third type of yield; either with the same investment vault to gain fees on flashloans or to use it on external deFi protocols in the same chain or on any other crossChain deFi protocol thanks to chainlinks CCIP.
<img width="616" alt="image" src="https://github.com/Kanoopz/lfghoHackathon/assets/43384993/88e2c256-5cd2-47cc-ade3-4591f14b42e6">
