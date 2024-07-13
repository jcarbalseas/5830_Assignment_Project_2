// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./BridgeToken.sol";

contract Destination is AccessControl {
    bytes32 public constant WARDEN_ROLE = keccak256("BRIDGE_WARDEN_ROLE");
    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");
	mapping( address => address) public underlying_tokens;
	mapping( address => address) public wrapped_tokens;
	address[] public tokens;

	event Creation( address indexed underlying_token, address indexed wrapped_token );
	event Wrap( address indexed underlying_token, address indexed wrapped_token, address indexed to, uint256 amount );
	event Unwrap( address indexed underlying_token, address indexed wrapped_token, address frm, address indexed to, uint256 amount );

    constructor( address admin ) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(CREATOR_ROLE, admin);
        _grantRole(WARDEN_ROLE, admin);
    }

	function wrap(address _underlying_token, address _recipient, uint256 _amount ) public onlyRole(WARDEN_ROLE) {
		//YOUR CODE HERE
 // Check that the underlying asset has been registered
        require(underlying_tokens[_underlying_token] != address(0), "Underlying asset not registered");

        // Lookup the BridgeToken corresponding to the underlying asset
        address wrappedTokenAddress = underlying_tokens[_underlying_token];
        BridgeToken wrappedToken = BridgeToken(wrappedTokenAddress);

        // Mint the correct amount of BridgeTokens to the recipient
        wrappedToken.mint(_recipient, _amount);

        // Emit a Wrap event
        emit Wrap(_underlying_token, wrappedTokenAddress, _recipient, _amount);
	}

	function unwrap(address _wrapped_token, address _recipient, uint256 _amount ) public {
		//YOUR CODE HERE
// Check that the wrapped token is registered
        require(wrapped_tokens[_wrapped_token] != address(0), "Wrapped token not registered");

        // Lookup the underlying token corresponding to the wrapped token
        address underlyingTokenAddress = wrapped_tokens[_wrapped_token];
        BridgeToken wrappedToken = BridgeToken(_wrapped_token);

        // Burn the specified amount of BridgeTokens from the sender's balance
        wrappedToken.burnFrom(msg.sender, _amount);

        // Emit an Unwrap event
        emit Unwrap(underlyingTokenAddress, _wrapped_token, msg.sender, _recipient, _amount);
	}

	function createToken(address _underlying_token, string memory name, string memory symbol ) public onlyRole(CREATOR_ROLE) returns(address) {
		//YOUR CODE HERE
// Deploy the new BridgeToken contract
        require(underlying_tokens[_underlying_token] == address(0), "Token already registered");

        
        BridgeToken newToken = new BridgeToken(_underlying_token, name, symbol, msg.sender);
        
        // Store the mapping between the underlying token and the wrapped token
        underlying_tokens[_underlying_token] = address(newToken);
        wrapped_tokens[address(newToken)] = _underlying_token;
        
        tokens.push(_underlying_token);


        // Emit the Creation event
        emit Creation(_underlying_token, address(newToken));
        
        // Return the address of the newly created BridgeToken contract
        return address(newToken);
    
	}

}

