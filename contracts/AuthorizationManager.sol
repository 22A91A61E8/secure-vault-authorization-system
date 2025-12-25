// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/**
 * @title AuthorizationManager
 * @notice Validates withdrawal permissions using ECDSA signatures
 * @dev Tracks authorization usage to prevent replay attacks
 */
contract AuthorizationManager {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    // Authorized signer address
    address public authorizedSigner;
    
    // Track used authorization identifiers (nonces)
    mapping(bytes32 => bool) public usedAuthorizations;
    
    // Events
    event AuthorizationUsed(bytes32 indexed authorizationId, address indexed recipient, uint256 amount);
    event SignerUpdated(address indexed previousSigner, address indexed newSigner);
    
    // Custom errors
    error InvalidSignature();
    error AuthorizationAlreadyUsed();
    error InvalidSigner();
    error OnlyVault();
    
    modifier onlyAuthorizedSigner() {
        if (msg.sender != authorizedSigner) revert InvalidSigner();
        _;
    }
    
    /**
     * @notice Initialize the contract with an authorized signer
     * @param _signer Address that can sign authorizations
     */
    constructor(address _signer) {
        require(_signer != address(0), "Invalid signer address");
        authorizedSigner = _signer;
        emit SignerUpdated(address(0), _signer);
    }
    
    /**
     * @notice Verify and consume an authorization
     * @param vaultAddress The vault contract address
     * @param recipient The withdrawal recipient
     * @param amount The withdrawal amount
     * @param nonce Unique identifier for this authorization
     * @param chainId The blockchain network ID
     * @param signature ECDSA signature from authorized signer
     * @return bool True if authorization is valid and consumed
     */
    function verifyAuthorization(
        address vaultAddress,
        address recipient,
        uint256 amount,
        uint256 nonce,
        uint256 chainId,
        bytes memory signature
    ) external returns (bool) {
        // Construct authorization ID
        bytes32 authorizationId = keccak256(
            abi.encodePacked(
                vaultAddress,
                recipient,
                amount,
                nonce,
                chainId
            )
        );
        
        // Check if authorization was already used
        if (usedAuthorizations[authorizationId]) {
            revert AuthorizationAlreadyUsed();
        }
        
        // Create message hash with Ethereum Signed Message prefix
        bytes32 messageHash = authorizationId.toEthSignedMessageHash();
        
        // Recover signer from signature
        address recoveredSigner = messageHash.recover(signature);
        
        // Verify the signer is authorized
        if (recoveredSigner != authorizedSigner) {
            revert InvalidSignature();
        }
        
        // Mark authorization as used (prevents replay)
        usedAuthorizations[authorizationId] = true;
        
        emit AuthorizationUsed(authorizationId, recipient, amount);
        
        return true;
    }
    
    /**
     * @notice Check if an authorization has been used
     * @param vaultAddress The vault contract address
     * @param recipient The withdrawal recipient
     * @param amount The withdrawal amount
     * @param nonce Unique identifier for this authorization
     * @param chainId The blockchain network ID
     * @return bool True if authorization has been used
     */
    function isAuthorizationUsed(
        address vaultAddress,
        address recipient,
        uint256 amount,
        uint256 nonce,
        uint256 chainId
    ) external view returns (bool) {
        bytes32 authorizationId = keccak256(
            abi.encodePacked(
                vaultAddress,
                recipient,
                amount,
                nonce,
                chainId
            )
        );
        return usedAuthorizations[authorizationId];
    }
    
    /**
     * @notice Update the authorized signer
     * @param newSigner New signer address
     */
    function updateSigner(address newSigner) external onlyAuthorizedSigner {
        require(newSigner != address(0), "Invalid signer address");
        address previousSigner = authorizedSigner;
        authorizedSigner = newSigner;
        emit SignerUpdated(previousSigner, newSigner);
    }
}
