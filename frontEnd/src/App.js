import logo from './logo.svg';
import './App.css';
import { ethers } from 'ethers';
import { useState } from 'react';

import { PaperEmbeddedWalletSdk } from "@paperxyz/embedded-wallet-service-sdk";
import { UserStatus } from "@paperxyz/embedded-wallet-service-sdk";

// import MailWalletConnect from './components/MailWalletConnect';
import { renderPaperCheckoutLink } from "@paperxyz/js-client-sdk";

function App() {

  // let smartContractAddress = "0x721351C2b518BE486b8771B92908F11DEF921B51";
  // let smartContractAbi = [
  //   {
  //     "inputs": [],
  //     "stateMutability": "nonpayable",
  //     "type": "constructor"
  //   },
  //   {
  //     "anonymous": false,
  //     "inputs": [
  //       {
  //         "indexed": true,
  //         "internalType": "address",
  //         "name": "owner",
  //         "type": "address"
  //       },
  //       {
  //         "indexed": true,
  //         "internalType": "address",
  //         "name": "approved",
  //         "type": "address"
  //       },
  //       {
  //         "indexed": true,
  //         "internalType": "uint256",
  //         "name": "tokenId",
  //         "type": "uint256"
  //       }
  //     ],
  //     "name": "Approval",
  //     "type": "event"
  //   },
  //   {
  //     "anonymous": false,
  //     "inputs": [
  //       {
  //         "indexed": true,
  //         "internalType": "address",
  //         "name": "owner",
  //         "type": "address"
  //       },
  //       {
  //         "indexed": true,
  //         "internalType": "address",
  //         "name": "operator",
  //         "type": "address"
  //       },
  //       {
  //         "indexed": false,
  //         "internalType": "bool",
  //         "name": "approved",
  //         "type": "bool"
  //       }
  //     ],
  //     "name": "ApprovalForAll",
  //     "type": "event"
  //   },
  //   {
  //     "anonymous": false,
  //     "inputs": [
  //       {
  //         "indexed": true,
  //         "internalType": "address",
  //         "name": "from",
  //         "type": "address"
  //       },
  //       {
  //         "indexed": true,
  //         "internalType": "address",
  //         "name": "to",
  //         "type": "address"
  //       },
  //       {
  //         "indexed": true,
  //         "internalType": "uint256",
  //         "name": "tokenId",
  //         "type": "uint256"
  //       }
  //     ],
  //     "name": "Transfer",
  //     "type": "event"
  //   },
  //   {
  //     "anonymous": false,
  //     "inputs": [
  //       {
  //         "indexed": false,
  //         "internalType": "string",
  //         "name": "msg",
  //         "type": "string"
  //       },
  //       {
  //         "indexed": false,
  //         "internalType": "address",
  //         "name": "investor",
  //         "type": "address"
  //       },
  //       {
  //         "indexed": false,
  //         "internalType": "uint256",
  //         "name": "amountTransfered",
  //         "type": "uint256"
  //       },
  //       {
  //         "indexed": false,
  //         "internalType": "uint256",
  //         "name": "balanceBefore",
  //         "type": "uint256"
  //       },
  //       {
  //         "indexed": false,
  //         "internalType": "uint256",
  //         "name": "balanceAfter",
  //         "type": "uint256"
  //       }
  //     ],
  //     "name": "ghoBalanceRetrieved",
  //     "type": "event"
  //   },
  //   {
  //     "anonymous": false,
  //     "inputs": [
  //       {
  //         "indexed": false,
  //         "internalType": "string",
  //         "name": "msg",
  //         "type": "string"
  //       },
  //       {
  //         "components": [
  //           {
  //             "internalType": "uint256",
  //             "name": "investmentId",
  //             "type": "uint256"
  //           },
  //           {
  //             "internalType": "address",
  //             "name": "investor",
  //             "type": "address"
  //           },
  //           {
  //             "internalType": "uint256",
  //             "name": "quantityOf10CentsOfEther",
  //             "type": "uint256"
  //           },
  //           {
  //             "internalType": "uint256",
  //             "name": "etherPriceInUsd",
  //             "type": "uint256"
  //           },
  //           {
  //             "internalType": "uint256",
  //             "name": "orderTotalInUsd",
  //             "type": "uint256"
  //           },
  //           {
  //             "internalType": "uint256",
  //             "name": "ghoAcquired",
  //             "type": "uint256"
  //           }
  //         ],
  //         "indexed": false,
  //         "internalType": "struct ghoInvestmentVault.investmentStruct",
  //         "name": "investment",
  //         "type": "tuple"
  //       }
  //     ],
  //     "name": "investment",
  //     "type": "event"
  //   },
  //   {
  //     "inputs": [
  //       {
  //         "internalType": "address",
  //         "name": "to",
  //         "type": "address"
  //       },
  //       {
  //         "internalType": "uint256",
  //         "name": "tokenId",
  //         "type": "uint256"
  //       }
  //     ],
  //     "name": "approve",
  //     "outputs": [],
  //     "stateMutability": "nonpayable",
  //     "type": "function"
  //   },
  //   {
  //     "inputs": [
  //       {
  //         "internalType": "address",
  //         "name": "owner",
  //         "type": "address"
  //       }
  //     ],
  //     "name": "balanceOf",
  //     "outputs": [
  //       {
  //         "internalType": "uint256",
  //         "name": "",
  //         "type": "uint256"
  //       }
  //     ],
  //     "stateMutability": "view",
  //     "type": "function"
  //   },
  //   {
  //     "inputs": [
  //       {
  //         "internalType": "uint256",
  //         "name": "paramQuantity",
  //         "type": "uint256"
  //       },
  //       {
  //         "internalType": "address",
  //         "name": "paramBuyer",
  //         "type": "address"
  //       }
  //     ],
  //     "name": "buyPointsWithEther",
  //     "outputs": [],
  //     "stateMutability": "payable",
  //     "type": "function"
  //   },
  //   {
  //     "inputs": [],
  //     "name": "claimEtherBack",
  //     "outputs": [],
  //     "stateMutability": "nonpayable",
  //     "type": "function"
  //   },
  //   {
  //     "inputs": [],
  //     "name": "counter",
  //     "outputs": [
  //       {
  //         "internalType": "uint256",
  //         "name": "",
  //         "type": "uint256"
  //       }
  //     ],
  //     "stateMutability": "view",
  //     "type": "function"
  //   },
  //   {
  //     "inputs": [
  //       {
  //         "internalType": "uint256",
  //         "name": "paramAmount",
  //         "type": "uint256"
  //       }
  //     ],
  //     "name": "flashloan",
  //     "outputs": [],
  //     "stateMutability": "nonpayable",
  //     "type": "function"
  //   },
  //   {
  //     "inputs": [
  //       {
  //         "internalType": "uint256",
  //         "name": "tokenId",
  //         "type": "uint256"
  //       }
  //     ],
  //     "name": "getApproved",
  //     "outputs": [
  //       {
  //         "internalType": "address",
  //         "name": "",
  //         "type": "address"
  //       }
  //     ],
  //     "stateMutability": "view",
  //     "type": "function"
  //   },
  //   {
  //     "inputs": [],
  //     "name": "getEthUsd",
  //     "outputs": [
  //       {
  //         "internalType": "int256",
  //         "name": "",
  //         "type": "int256"
  //       }
  //     ],
  //     "stateMutability": "view",
  //     "type": "function"
  //   },
  //   {
  //     "inputs": [
  //       {
  //         "internalType": "address",
  //         "name": "paramAddress",
  //         "type": "address"
  //       }
  //     ],
  //     "name": "getGhoBalanceOfAddress",
  //     "outputs": [
  //       {
  //         "internalType": "uint256",
  //         "name": "",
  //         "type": "uint256"
  //       }
  //     ],
  //     "stateMutability": "view",
  //     "type": "function"
  //   },
  //   {
  //     "inputs": [
  //       {
  //         "internalType": "uint256",
  //         "name": "paramQuantity",
  //         "type": "uint256"
  //       }
  //     ],
  //     "name": "invest",
  //     "outputs": [],
  //     "stateMutability": "payable",
  //     "type": "function"
  //   },
  //   {
  //     "inputs": [
  //       {
  //         "internalType": "uint256",
  //         "name": "",
  //         "type": "uint256"
  //       }
  //     ],
  //     "name": "investmentNftsData",
  //     "outputs": [
  //       {
  //         "internalType": "uint256",
  //         "name": "investmentId",
  //         "type": "uint256"
  //       },
  //       {
  //         "internalType": "address",
  //         "name": "investor",
  //         "type": "address"
  //       },
  //       {
  //         "internalType": "uint256",
  //         "name": "quantityOf10CentsOfEther",
  //         "type": "uint256"
  //       },
  //       {
  //         "internalType": "uint256",
  //         "name": "etherPriceInUsd",
  //         "type": "uint256"
  //       },
  //       {
  //         "internalType": "uint256",
  //         "name": "orderTotalInUsd",
  //         "type": "uint256"
  //       },
  //       {
  //         "internalType": "uint256",
  //         "name": "ghoAcquired",
  //         "type": "uint256"
  //       }
  //     ],
  //     "stateMutability": "view",
  //     "type": "function"
  //   },
  //   {
  //     "inputs": [
  //       {
  //         "internalType": "uint256",
  //         "name": "paramAmountToRetrieve",
  //         "type": "uint256"
  //       }
  //     ],
  //     "name": "investorRetrieveGhoToken",
  //     "outputs": [],
  //     "stateMutability": "nonpayable",
  //     "type": "function"
  //   },
  //   {
  //     "inputs": [
  //       {
  //         "internalType": "address",
  //         "name": "",
  //         "type": "address"
  //       }
  //     ],
  //     "name": "investorsAaveV3Credit",
  //     "outputs": [
  //       {
  //         "internalType": "uint256",
  //         "name": "",
  //         "type": "uint256"
  //       }
  //     ],
  //     "stateMutability": "view",
  //     "type": "function"
  //   },
  //   {
  //     "inputs": [
  //       {
  //         "internalType": "address",
  //         "name": "",
  //         "type": "address"
  //       }
  //     ],
  //     "name": "investorsGhoBalance",
  //     "outputs": [
  //       {
  //         "internalType": "uint256",
  //         "name": "",
  //         "type": "uint256"
  //       }
  //     ],
  //     "stateMutability": "view",
  //     "type": "function"
  //   },
  //   {
  //     "inputs": [
  //       {
  //         "internalType": "address",
  //         "name": "owner",
  //         "type": "address"
  //       },
  //       {
  //         "internalType": "address",
  //         "name": "operator",
  //         "type": "address"
  //       }
  //     ],
  //     "name": "isApprovedForAll",
  //     "outputs": [
  //       {
  //         "internalType": "bool",
  //         "name": "",
  //         "type": "bool"
  //       }
  //     ],
  //     "stateMutability": "view",
  //     "type": "function"
  //   },
  //   {
  //     "inputs": [
  //       {
  //         "internalType": "address",
  //         "name": "paramDelegatee",
  //         "type": "address"
  //       },
  //       {
  //         "internalType": "uint256",
  //         "name": "paramAmount",
  //         "type": "uint256"
  //       },
  //       {
  //         "internalType": "string",
  //         "name": "paramOffChainLegalAgreement",
  //         "type": "string"
  //       },
  //       {
  //         "internalType": "uint256",
  //         "name": "paramPercentageFee",
  //         "type": "uint256"
  //       }
  //     ],
  //     "name": "makeCreditDelegation",
  //     "outputs": [],
  //     "stateMutability": "nonpayable",
  //     "type": "function"
  //   },
  //   {
  //     "inputs": [],
  //     "name": "name",
  //     "outputs": [
  //       {
  //         "internalType": "string",
  //         "name": "",
  //         "type": "string"
  //       }
  //     ],
  //     "stateMutability": "view",
  //     "type": "function"
  //   },
  //   {
  //     "inputs": [],
  //     "name": "owner",
  //     "outputs": [
  //       {
  //         "internalType": "address",
  //         "name": "",
  //         "type": "address"
  //       }
  //     ],
  //     "stateMutability": "view",
  //     "type": "function"
  //   },
  //   {
  //     "inputs": [
  //       {
  //         "internalType": "uint256",
  //         "name": "tokenId",
  //         "type": "uint256"
  //       }
  //     ],
  //     "name": "ownerOf",
  //     "outputs": [
  //       {
  //         "internalType": "address",
  //         "name": "",
  //         "type": "address"
  //       }
  //     ],
  //     "stateMutability": "view",
  //     "type": "function"
  //   },
  //   {
  //     "inputs": [
  //       {
  //         "internalType": "uint256",
  //         "name": "paramAmount",
  //         "type": "uint256"
  //       }
  //     ],
  //     "name": "retrieveWethFromAavePool",
  //     "outputs": [],
  //     "stateMutability": "nonpayable",
  //     "type": "function"
  //   },
  //   {
  //     "inputs": [
  //       {
  //         "internalType": "address",
  //         "name": "from",
  //         "type": "address"
  //       },
  //       {
  //         "internalType": "address",
  //         "name": "to",
  //         "type": "address"
  //       },
  //       {
  //         "internalType": "uint256",
  //         "name": "tokenId",
  //         "type": "uint256"
  //       }
  //     ],
  //     "name": "safeTransferFrom",
  //     "outputs": [],
  //     "stateMutability": "nonpayable",
  //     "type": "function"
  //   },
  //   {
  //     "inputs": [
  //       {
  //         "internalType": "address",
  //         "name": "from",
  //         "type": "address"
  //       },
  //       {
  //         "internalType": "address",
  //         "name": "to",
  //         "type": "address"
  //       },
  //       {
  //         "internalType": "uint256",
  //         "name": "tokenId",
  //         "type": "uint256"
  //       },
  //       {
  //         "internalType": "bytes",
  //         "name": "data",
  //         "type": "bytes"
  //       }
  //     ],
  //     "name": "safeTransferFrom",
  //     "outputs": [],
  //     "stateMutability": "nonpayable",
  //     "type": "function"
  //   },
  //   {
  //     "inputs": [
  //       {
  //         "internalType": "address",
  //         "name": "operator",
  //         "type": "address"
  //       },
  //       {
  //         "internalType": "bool",
  //         "name": "approved",
  //         "type": "bool"
  //       }
  //     ],
  //     "name": "setApprovalForAll",
  //     "outputs": [],
  //     "stateMutability": "nonpayable",
  //     "type": "function"
  //   },
  //   {
  //     "inputs": [
  //       {
  //         "internalType": "bytes4",
  //         "name": "interfaceId",
  //         "type": "bytes4"
  //       }
  //     ],
  //     "name": "supportsInterface",
  //     "outputs": [
  //       {
  //         "internalType": "bool",
  //         "name": "",
  //         "type": "bool"
  //       }
  //     ],
  //     "stateMutability": "view",
  //     "type": "function"
  //   },
  //   {
  //     "inputs": [],
  //     "name": "symbol",
  //     "outputs": [
  //       {
  //         "internalType": "string",
  //         "name": "",
  //         "type": "string"
  //       }
  //     ],
  //     "stateMutability": "view",
  //     "type": "function"
  //   },
  //   {
  //     "inputs": [
  //       {
  //         "internalType": "uint256",
  //         "name": "tokenId",
  //         "type": "uint256"
  //       }
  //     ],
  //     "name": "tokenURI",
  //     "outputs": [
  //       {
  //         "internalType": "string",
  //         "name": "",
  //         "type": "string"
  //       }
  //     ],
  //     "stateMutability": "view",
  //     "type": "function"
  //   },
  //   {
  //     "inputs": [
  //       {
  //         "internalType": "address",
  //         "name": "from",
  //         "type": "address"
  //       },
  //       {
  //         "internalType": "address",
  //         "name": "to",
  //         "type": "address"
  //       },
  //       {
  //         "internalType": "uint256",
  //         "name": "tokenId",
  //         "type": "uint256"
  //       }
  //     ],
  //     "name": "transferFrom",
  //     "outputs": [],
  //     "stateMutability": "nonpayable",
  //     "type": "function"
  //   },
  //   {
  //     "inputs": [],
  //     "name": "vaultGhoInPossession",
  //     "outputs": [
  //       {
  //         "internalType": "uint256",
  //         "name": "",
  //         "type": "uint256"
  //       }
  //     ],
  //     "stateMutability": "view",
  //     "type": "function"
  //   },
  //   {
  //     "stateMutability": "payable",
  //     "type": "receive"
  //   }
  // ];

  // let provider = new ethers.providers.Web3Provider(window.ethereum);
  // let smartContractInstance = new ethers.Contract(smartContractAddress, smartContractAbi, provider);






  const sdk = new PaperEmbeddedWalletSdk({
    clientId: '3dea475c-58f6-48a7-b38c-ed8220ab813b',
    chain: 'Mumbai',
  });

  async function connectMailWallet()
  {
    let _user = await sdk.auth.loginWithPaperModal();
    setUser(_user);

    let data = await sdk.getUser();
    let _address = data.walletAddress;
    setAddress(_address);
    connect();
  }

  async function getMailWalletInfo()
  {
    const result = await sdk.getUser();

    console.log("Info");
    console.log(result);

    const signer = await user.wallet.getEthersJsSigner();
    console.log("signer");
    console.log(signer);
  }

  async function getMailSigner()
  {
    const _signer = await user.wallet.getEthersJsSigner({rpcEndpoint: "https://rpc-mumbai.maticvigil.com",});
    console.log(_signer);
    setSigner(_signer);
  }


  const openCheckout = () => renderPaperCheckoutLink
  (
      {
        checkoutLinkUrl: "https://withpaper.com/checkout/88971b32-a9e4-42e0-89d4-219c26ca6a15",
      }
  );


  const [user, setUser] = useState(null);
  const [address, setAddress] = useState(null);
  const [signer, setSigner] = useState(null);
  const [userConnected, setUserConnected] = useState(null);




  // async function requestAccount() 
  // {
  //   if(window.ethereum)
  //   {
  //     let accounts = await window.ethereum.request({ method: "eth_requestAccounts", });

  //     const _signer = await provider.getSigner();
  //     const _address = accounts[0];

  //     setAddress(_address);
  //     setSigner(_signer);
  //     setUserConnected(true);

  //     console.log("signer");
  //     console.log(_signer);
  //     console.log("address:");
  //     console.log(_address);
  //   }
  //   else
  //   {
  //     console.log("Metamask isnt installed.");
  //   }

  //   console.log("userObject:");
  //   console.log(signer);
  // }

  function connect()
  {
    setUserConnected(true);
  }

  // async function mintFunction()
  // {
  //   // const gasPrice = smartContractInstance.gasPrice();

  //   // const gas = await smartContractInstance.estimateGas.invest(1);

  //   // const tx = await smartContractInstance.connect(signer).invest(1, {gasLimit: ((gas * 10090) / 100)});

  //   const tx = await smartContractInstance.connect(signer).buyPointsWithEther(3, address);
  //   await tx.wait();
  // }



  return (
    <div>
      <header>
        ghoInvestmentVault
      </header>

      <body>
        {
          userConnected ?
            <>
              <h2>userAddress: {address}</h2>

              <div>
                <button onClick={getMailSigner}>getMailSigner</button>
              </div>

              <div style={{paddingTop: '2rem'}}>
                <div>
                  <h2>Buy with creditCard</h2>
                  <button onClick={openCheckout}>Buy with Paper</button>
                </div>
              </div>
            </>
          :
            <>
              <button onClick={connectMailWallet}>connectWithMailWallet</button>
            </>
        }
      </body>
    </div>
  );
}

export default App;
