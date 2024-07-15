// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./BridgeToken.sol";

contract Destination is AccessControl {
    bytes32 public constant WARDEN_ROLE = keccak256("BRIDGE_WARDEN_ROLE");
    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");
    mapping(address => address) public underlying_tokens; // Maps wrapped tokens to underlying tokens
    mapping(address => address) public wrapped_tokens;    // Maps underlying tokens to wrapped tokens
    address[] public tokens;

    event Creation(address indexed underlying_token, address indexed wrapped_token);
    event Wrap(address indexed underlying_token, address indexed wrapped_token, address indexed to, uint256 amount);
    event Unwrap(address indexed underlying_token, address indexed wrapped_token, address frm, address indexed to, uint256 amount);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(CREATOR_ROLE, admin);
        _grantRole(WARDEN_ROLE, admin);
    }

    function wrap(address _underlying_token, address _recipient, uint256 _amount) public onlyRole(WARDEN_ROLE) {
        // Ensure the amount is greater than zero
        require(_amount > 0, "Amount must be greater than zero");
        
        // Check if the wrapped token for the underlying token exists
        require(wrapped_tokens[_underlying_token] != address(0), "Wrapped token not created");

        // Mint the wrapped token to the recipient
        BridgeToken wrappedToken = BridgeToken(wrapped_tokens[_underlying_token]);
        wrappedToken.mint(_recipient, _amount);

        // Emit the wrap event
        emit Wrap(_underlying_token, wrapped_tokens[_underlying_token], _recipient, _amount);
    }

    function unwrap(address _wrapped_token, address _recipient, uint256 _amount) public {
        // Ensure the amount is greater than zero
        require(_amount > 0, "Amount must be greater than zero");

        // Check if the underlying token for the wrapped token exists
        require(underlying_tokens[_wrapped_token] != address(0), "Underlying token not registered");

        // Burn the wrapped token from the sender
        BridgeToken wrappedToken = BridgeToken(_wrapped_token);
        wrappedToken.burnFrom(msg.sender, _amount);

        // Emit the unwrap event
        emit Unwrap(underlying_tokens[_wrapped_token], _wrapped_token, msg.sender, _recipient, _amount);
    }

    function createToken(address _underlying_token, string memory name, string memory symbol) public onlyRole(CREATOR_ROLE) returns (address) {
        // Check if the token has already been created
        require(underlying_tokens[_underlying_token] == address(0), "Token already created");

        // Create a new BridgeToken with the contract itself as the minter
        BridgeToken newToken = new BridgeToken(_underlying_token, name, symbol, address(this)); // Assign address(this) as the minter

        // Map the underlying token to the new wrapped token and vice versa
        wrapped_tokens[_underlying_token] = address(newToken); // Corrected mapping
        underlying_tokens[address(newToken)] = _underlying_token; // Corrected mapping

        // Add the new token to the list of tokens
        tokens.push(_underlying_token);

        // Emit the creation event
        emit Creation(_underlying_token, address(newToken));

        // Return the address of the new wrapped token
        return address(newToken);
    }
}
