//SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/token/ERC20/IERC20.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';
import {IGhoToken} from './gho/interfaces/IGhoToken.sol';
import {IAccessControl} from '@openzeppelin/contracts/access/IAccessControl.sol';

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";



contract ccipGhoToken is CCIPReceiver, OwnerIsCreator, Context
{
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //      "customErrors"                                                                                                                                   ///
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees); // Used to make sure contract has enough balance.
    error NothingToWithdraw(); // Used when trying to withdraw Ether but there's nothing to withdraw.
    error FailedToWithdrawEth(address owner, address target, uint256 value); // Used when the withdrawal of Ether fails.
    error DestinationChainNotWhitelisted(uint64 destinationChainSelector); // Used when the destination chain has not been whitelisted by the contract owner.
    error SourceChainNotWhitelisted(uint64 sourceChainSelector); // Used when the source chain has not been whitelisted by the contract owner.
    error SenderNotWhitelisted(address sender); // Used when the sender has not been whitelisted by the contract owner.



    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //      "EVENTS"                                                                                                                                         ///
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    event MessageSent
    (
        bytes32 indexed messageId, // The unique ID of the CCIP message.
        uint64 indexed destinationChainSelector, // The chain selector of the destination chain.
        address receiver, // The address of the receiver on the destination chain.
        string text, // The text being sent.
        address feeToken, // the token address used to pay CCIP fees.
        uint256 fees // The fees paid for sending the CCIP message.
    );
    
    event MessageReceived
    (
        bytes32 indexed messageId, // The unique ID of the CCIP message.
        uint64 indexed sourceChainSelector, // The chain selector of the source chain.
        address sender, // The address of the sender from the source chain.
        string text // The text that was received.
    );

    event TokensTransferred
    (
        bytes32 indexed messageId, // The unique ID of the message.
        uint64 indexed destinationChainSelector, // The chain selector of the destination chain.
        address receiver, // The address of the receiver on the destination chain.
        address token, // The token address that was transferred.
        uint256 tokenAmount, // The token amount that was transferred.
        address feeToken, // the token address used to pay CCIP fees.
        uint256 fees // The fees paid for sending the message.
    );



    /**
   * @dev Emitted when a new facilitator is added
   * @param facilitatorAddress The address of the new facilitator
   * @param label A hashed human readable identifier for the facilitator
   * @param bucketCapacity The initial capacity of the facilitator's bucket
   */
  event FacilitatorAdded(
    address indexed facilitatorAddress,
    bytes32 indexed label,
    uint256 bucketCapacity
  );

    /**
   * @dev Emitted when a facilitator is removed
   * @param facilitatorAddress The address of the removed facilitator
   */
  event FacilitatorRemoved(address indexed facilitatorAddress);

  /**
   * @dev Emitted when the bucket capacity of a facilitator is updated
   * @param facilitatorAddress The address of the facilitator whose bucket capacity is being changed
   * @param oldCapacity The old capacity of the bucket
   * @param newCapacity The new capacity of the bucket
   */
  event FacilitatorBucketCapacityUpdated(
    address indexed facilitatorAddress,
    uint256 oldCapacity,
    uint256 newCapacity
  );

  /**
   * @dev Emitted when the bucket level changed
   * @param facilitatorAddress The address of the facilitator whose bucket level is being changed
   * @param oldLevel The old level of the bucket
   * @param newLevel The new level of the bucket
   */
  event FacilitatorBucketLevelUpdated(
    address indexed facilitatorAddress,
    uint256 oldLevel,
    uint256 newLevel
  );



    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //      "MODIFIERS"                                                                                                                                      ///
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    modifier onlyWhitelistedDestinationChain(uint64 _destinationChainSelector) 
    {
        if (!whitelistedDestinationChains[_destinationChainSelector])
            revert DestinationChainNotWhitelisted(_destinationChainSelector);
        _;
    }

    modifier onlyWhitelistedSourceChain(uint64 _sourceChainSelector) 
    {
        if (!whitelistedSourceChains[_sourceChainSelector])
            revert SourceChainNotWhitelisted(_sourceChainSelector);
        _;
    }

    modifier onlyWhitelistedSenders(address _sender) 
    {
        if (!whitelistedSenders[_sender]) revert SenderNotWhitelisted(_sender);
        _;
    }

    modifier onlyWhitelistedChain(uint64 _destinationChainSelector) 
    {
        if (!whitelistedChains[_destinationChainSelector])
            revert DestinationChainNotWhitelisted(_destinationChainSelector);
        _;
    }

    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
        }
    }

    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
        return _roles[role].members[account];
    }



    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //      "STORAGE"                                                                                                                                        ///
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////
    //      "erc20"                                            ///
    //////////////////////////////////////////////////////////////
    using EnumerableSet for EnumerableSet.AddressSet;

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    struct Facilitator 
    {
        uint128 bucketCapacity;
        uint128 bucketLevel;
        string label;
    }

    string public name;
    string public symbol; 
    uint8 public immutable decimals;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    bytes32 public constant PERMIT_TYPEHASH =
    keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    //////////////////////////////////////////////////////////////
    //      "ghoToken"                                         ///
    //////////////////////////////////////////////////////////////
    mapping(address => Facilitator) internal _facilitators;
    EnumerableSet.AddressSet internal _facilitatorsList;

    bytes32 public constant FACILITATOR_MANAGER_ROLE = keccak256('FACILITATOR_MANAGER_ROLE');

    bytes32 public constant BUCKET_MANAGER_ROLE = keccak256('BUCKET_MANAGER_ROLE');

    //////////////////////////////////////////////////////////////
    //      "VARIABLES"                                        ///
    //////////////////////////////////////////////////////////////
    LinkTokenInterface linkToken;

    //////////////////////////////////////////////////////////////
    //      "interfaceVariables"                               ///
    //////////////////////////////////////////////////////////////
    IRouterClient router;

    //////////////////////////////////////////////////////////////
    //      "MAPPINGS"                                         ///
    //////////////////////////////////////////////////////////////
    mapping(uint64 => bool) public whitelistedDestinationChains;
    mapping(uint64 => bool) public whitelistedSourceChains;
    mapping(address => bool) public whitelistedSenders;
    mapping(uint64 => bool) public whitelistedChains;



    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //      "FUNCTIONS"                                                                                                                                      ///
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////
    //      "CONSTRUCTOR"                                      ///
    //////////////////////////////////////////////////////////////
    constructor(string memory _name, string memory _symbol, uint8 _decimals, address _router) CCIPReceiver(_router) 
    {
        router = IRouterClient(_router); 

        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(FACILITATOR_MANAGER_ROLE, msg.sender);
        _setupRole(BUCKET_MANAGER_ROLE, msg.sender);

        addFacilitator(msg.sender, "ghoInvestmentVault", (10_000_000 * (10 ** 18)));
    }

    //////////////////////////////////////////////////////////////
    //      "ghoErc20Functions"                                ///
    //////////////////////////////////////////////////////////////
    function approve(address spender, uint256 amount) public virtual returns (bool) 
    {
        allowance[msg.sender][spender] = amount;

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
        balanceOf[to] += amount;
        }

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
        balanceOf[to] += amount;
        }

        return true;
    }

    function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, 'PERMIT_DEADLINE_EXPIRED');

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
        bytes32 digest = keccak256(
            abi.encodePacked(
            '\x19\x01',
            DOMAIN_SEPARATOR(),
            keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );

        address recoveredAddress = ecrecover(digest, v, r, s);

        require(recoveredAddress != address(0) && recoveredAddress == owner, 'INVALID_SIGNER');

        allowance[recoveredAddress][spender] = value;
        }
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
        keccak256(
            abi.encode(
            keccak256(
                'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
            ),
            keccak256(bytes(name)),
            keccak256('1'),
            block.chainid,
            address(this)
            )
        );
    }

    function _mint(address to, uint256 amount) internal virtual 
    {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
        balanceOf[to] += amount;
        }
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
        totalSupply -= amount;
        }
    }



    function mint(address account, uint256 amount) external 
    {
        require(amount > 0, 'INVALID_MINT_AMOUNT');
        Facilitator storage f = _facilitators[msg.sender];

        uint256 currentBucketLevel = f.bucketLevel;
        uint256 newBucketLevel = currentBucketLevel + amount;
        require(f.bucketCapacity >= newBucketLevel, 'FACILITATOR_BUCKET_CAPACITY_EXCEEDED');
        f.bucketLevel = uint128(newBucketLevel);

        _mint(account, amount);

        emit FacilitatorBucketLevelUpdated(msg.sender, currentBucketLevel, newBucketLevel);
    }

    function burn(uint256 amount) external 
    {
        require(amount > 0, 'INVALID_BURN_AMOUNT');

        Facilitator storage f = _facilitators[msg.sender];
        uint256 currentBucketLevel = f.bucketLevel;
        uint256 newBucketLevel = currentBucketLevel - amount;
        f.bucketLevel = uint128(newBucketLevel);

        _burn(msg.sender, amount);

        emit FacilitatorBucketLevelUpdated(msg.sender, currentBucketLevel, newBucketLevel);
    }

    function addFacilitator(
        address facilitatorAddress,
        string memory facilitatorLabel,
        uint128 bucketCapacity
    ) public onlyRole(FACILITATOR_MANAGER_ROLE) 
    {
        Facilitator storage facilitator = _facilitators[facilitatorAddress];

        require(bytes(facilitator.label).length == 0, 'FACILITATOR_ALREADY_EXISTS');
        require(bytes(facilitatorLabel).length > 0, 'INVALID_LABEL');

        facilitator.label = facilitatorLabel;
        facilitator.bucketCapacity = bucketCapacity;

        _facilitatorsList.add(facilitatorAddress);

        emit FacilitatorAdded(
        facilitatorAddress,
        keccak256(abi.encodePacked(facilitatorLabel)),
        bucketCapacity
        );
    }

    function removeFacilitator(
        address facilitatorAddress
    ) external onlyRole(FACILITATOR_MANAGER_ROLE) 
    {
        require(
        bytes(_facilitators[facilitatorAddress].label).length > 0,
        'FACILITATOR_DOES_NOT_EXIST'
        );
        require(
        _facilitators[facilitatorAddress].bucketLevel == 0,
        'FACILITATOR_BUCKET_LEVEL_NOT_ZERO'
        );

        delete _facilitators[facilitatorAddress];
        _facilitatorsList.remove(facilitatorAddress);

        emit FacilitatorRemoved(facilitatorAddress);
    }

    function setFacilitatorBucketCapacity(
        address facilitator,
        uint128 newCapacity
    ) external onlyRole(BUCKET_MANAGER_ROLE) 
    {
        require(bytes(_facilitators[facilitator].label).length > 0, 'FACILITATOR_DOES_NOT_EXIST');

        uint256 oldCapacity = _facilitators[facilitator].bucketCapacity;
        _facilitators[facilitator].bucketCapacity = newCapacity;

        emit FacilitatorBucketCapacityUpdated(facilitator, oldCapacity, newCapacity);
    }

    function getFacilitator(address facilitator) external view returns (Facilitator memory) 
    {
        return _facilitators[facilitator];
    }

    function getFacilitatorBucket(address facilitator) external view returns (uint256, uint256) 
    {
        return (_facilitators[facilitator].bucketCapacity, _facilitators[facilitator].bucketLevel);
    }

    function getFacilitatorsList() external view returns (address[] memory) 
    {
        return _facilitatorsList.values();
    }

    //////////////////////////////////////////////////////////////
    //      "ccipWhitelistingFunctions"                        ///
    //////////////////////////////////////////////////////////////
    function whitelistDestinationChain(uint64 _destinationChainSelector) public onlyOwner 
    {
        whitelistedDestinationChains[_destinationChainSelector] = true;
    }

    function denylistDestinationChain(uint64 _destinationChainSelector) public onlyOwner 
    {
        whitelistedDestinationChains[_destinationChainSelector] = false;
    }

    function whitelistSourceChain(uint64 _sourceChainSelector) public onlyOwner 
    {
        whitelistedSourceChains[_sourceChainSelector] = true;
    }

    function denylistSourceChain(uint64 _sourceChainSelector) public onlyOwner 
    {
        whitelistedSourceChains[_sourceChainSelector] = false;
    }

    function whitelistSender(address _sender) public onlyOwner 
    {
        whitelistedSenders[_sender] = true;
    }

    function denySender(address _sender) public onlyOwner 
    {
        whitelistedSenders[_sender] = false;
    }

    function whitelistChain(uint64 _destinationChainSelector) public onlyOwner 
    {
        whitelistedChains[_destinationChainSelector] = true;
    }

    function denylistChain(uint64 _destinationChainSelector) public onlyOwner 
    {
        whitelistedChains[_destinationChainSelector] = false;
    }

    //////////////////////////////////////////////////////////////
    //      "ccipMessaging"                                    ///
    //////////////////////////////////////////////////////////////
    function _buildCCIPMessage(address _receiver, address _token, uint256 _amount, address _feeTokenAddress) internal pure returns (Client.EVM2AnyMessage memory) {
        // Set the token amounts
        Client.EVMTokenAmount[]
            memory tokenAmounts = new Client.EVMTokenAmount[](1);
        Client.EVMTokenAmount memory tokenAmount = Client.EVMTokenAmount({
            token: _token,
            amount: _amount
        });
        tokenAmounts[0] = tokenAmount;
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver), // ABI-encoded receiver address
            data: "", // No data
            tokenAmounts: tokenAmounts, // The amount and type of token being transferred
            extraArgs: Client._argsToBytes(
                // Additional arguments, setting gas limit to 0 as we are not sending any data and non-strict sequencing mode
                Client.EVMExtraArgsV1({gasLimit: 0, strict: false})
            ),
            // Set the feeToken to a feeTokenAddress, indicating specific asset will be used for fees
            feeToken: _feeTokenAddress
        });
        return evm2AnyMessage;
    }


    // function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage) internal virtual override
    //     onlyWhitelistedSourceChain(any2EvmMessage.sourceChainSelector) // Make sure source chain is whitelisted
    //     onlyWhitelistedSenders(abi.decode(any2EvmMessage.sender, (address))) // Make sure the sender is whitelisted
    // {
        
    //     emit MessageReceived
    //     (
    //         any2EvmMessage.messageId,
    //         any2EvmMessage.sourceChainSelector, // fetch the source chain identifier (aka selector)
    //         abi.decode(any2EvmMessage.sender, (address)), // abi-decoding of the sender address,
    //         "received"
    //     );
    // }

    function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage) internal virtual override
        onlyWhitelistedSourceChain(any2EvmMessage.sourceChainSelector) // Make sure source chain is whitelisted
        onlyWhitelistedSenders(abi.decode(any2EvmMessage.sender, (address))) // Make sure the sender is whitelisted
    {
        (uint256 amount, address to) = abi.decode(any2EvmMessage.data, (uint256, address));
        balanceOf[to] -= amount;

        emit MessageReceived
        (
            any2EvmMessage.messageId,
            any2EvmMessage.sourceChainSelector, // fetch the source chain identifier (aka selector)
            abi.decode(any2EvmMessage.sender, (address)), // abi-decoding of the sender address,
            "received"
        );
    }

    function _funcsBuildCCIPMessage(address _receiver, address _feeTokenAddress, uint256 operation, string memory name, address nftOrTo, bytes memory data, uint256 value) internal pure returns (Client.EVM2AnyMessage memory) 
    {
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver), // ABI-encoded receiver address
            data: abi.encode(operation, name, nftOrTo, data, value), // ABI-encoded string
            tokenAmounts: new Client.EVMTokenAmount[](0), // Empty array aas no tokens are transferred
            extraArgs: Client._argsToBytes(
                // Additional arguments, setting gas limit and non-strict sequencing mode
                Client.EVMExtraArgsV1({gasLimit: 4_000_000, strict: false})
            ),
            // Set the feeToken to a feeTokenAddress, indicating specific asset will be used for fees
            feeToken: _feeTokenAddress
        });

        return evm2AnyMessage;
    }

    function crossChainTransferPayNative(uint64 _destinationChainSelector, address _receiver, address to, uint256 _amount) internal onlyWhitelistedDestinationChain(_destinationChainSelector) returns (bytes32 messageId)
    {
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        // address(0) means fees are paid in native gas
        Client.EVM2AnyMessage memory evm2AnyMessage =  _funcsBuildCCIPMessageToTransfer(_receiver, _amount, to, address(0), 0);

        // Get the fee required to send the message
        uint256 fees = router.getFee(_destinationChainSelector, evm2AnyMessage);

        if (fees > address(this).balance)
            revert NotEnoughBalance(address(this).balance, fees);

        // approve the Router to spend tokens on contract's behalf. It will spend the amount of the given token
        // IERC20(_token).approve(address(s_router), _amount);

        // Send the message through the router and store the returned message ID
        messageId = router.ccipSend{value: fees}(_destinationChainSelector, evm2AnyMessage);

        // Return the message ID
        return messageId;
    }

    function _funcsBuildCCIPMessageToTransfer(address _receiver, uint256 amount, address to, address _feeTokenAddress, uint256 operation) internal pure returns (Client.EVM2AnyMessage memory) 
    {
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver), // ABI-encoded receiver address
            data: abi.encode(amount, to), // ABI-encoded string
            tokenAmounts: new Client.EVMTokenAmount[](0), // Empty array aas no tokens are transferred
            extraArgs: Client._argsToBytes(
                // Additional arguments, setting gas limit and non-strict sequencing mode
                Client.EVMExtraArgsV1({gasLimit: 4_000_000, strict: false})
            ),
            // Set the feeToken to a feeTokenAddress, indicating specific asset will be used for fees
            feeToken: _feeTokenAddress
        });

        return evm2AnyMessage;
    }

    //////////////////////////////////////////////////////////////
    //      "etherRelatedFunctions"                            ///
    //////////////////////////////////////////////////////////////
    receive() external payable {}

    function withdraw(address _beneficiary) public onlyOwner 
    {
        // Retrieve the balance of this contract
        uint256 amount = address(this).balance;

        // Revert if there is nothing to withdraw
        if (amount == 0) revert NothingToWithdraw();

        // Attempt to send the funds, capturing the success status and discarding any return data
        (bool sent, ) = _beneficiary.call{value: amount}("");

        // Revert if the send failed, with information about the attempted transfer
        if (!sent) revert FailedToWithdrawEth(msg.sender, _beneficiary, amount);
    }
}