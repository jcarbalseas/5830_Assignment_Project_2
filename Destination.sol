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
	require(_amount > 0, "Amount must be greater than zero");
        require(underlying_tokens[_underlying_token] != address(0), "Underlying asset not registered");

        address wrappedTokenAddress = underlying_tokens[_underlying_token];
        BridgeToken wrappedToken = BridgeToken(wrappedTokenAddress);

        ERC20 underlyingToken = ERC20(_underlying_token);
        require(underlyingToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        wrappedToken.mint(_recipient, _amount);

        emit Wrap(_underlying_token, wrappedTokenAddress, _recipient, _amount);
	}

	function unwrap(address _wrapped_token, address _recipient, uint256 _amount ) public {
		//YOUR CODE HERE
	require(_amount > 0, "Amount must be greater than zero");
        require(wrapped_tokens[_wrapped_token] != address(0), "Wrapped token not registered");

        address underlyingTokenAddress = wrapped_tokens[_wrapped_token];
        BridgeToken wrappedToken = BridgeToken(_wrapped_token);

        ERC20 underlyingToken = ERC20(underlyingTokenAddress);
        require(underlyingToken.transfer(_recipient, _amount), "Token transfer failed");

        wrappedToken.burnFrom(msg.sender, _amount);
     
        wrapped_tokens[_wrapped_token] = address(0);
        underlying_tokens[underlyingTokenAddress] = address(0);
        // tokens.remove(underlyingTokenAddress);

        emit Unwrap(underlyingTokenAddress, _wrapped_token, msg.sender, _recipient, _amount);
	}

	function createToken(address _underlying_token, string memory name, string memory symbol ) public onlyRole(CREATOR_ROLE) returns(address) {
		//YOUR CODE HERE
        if (underlying_tokens[_underlying_token] == address(0)){
          return address(underlying_tokens[_underlying_token]);
        }
        require(underlying_tokens[_underlying_token] == address(0), "Token already created");

        BridgeToken newToken = new BridgeToken(_underlying_token, name, symbol, msg.sender);
        
        underlying_tokens[_underlying_token] = address(newToken);
        wrapped_tokens[address(newToken)] = _underlying_token;
        
        tokens.push(_underlying_token);

        emit Creation(_underlying_token, address(newToken));
        
        return address(newToken);
    
	}

}
