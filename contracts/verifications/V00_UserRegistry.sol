/*
  Copyright (c) 2018-present evan GmbH.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.4.24;

import "../Core.sol";
import "./VerificationHolder.sol";


/// @title UserRegistry
/// @dev Used to keep registry of user identifies
/// @author Matt Liu <matt@originprotocol.com>, Josh Fraser <josh@originprotocol.com>, Stan James <stan@originprotocol.com>


contract V00_UserRegistry is Owned {
    /*
    * Events
    */

    event NewUser(address _address, address _identity);

    /*
    * Storage
    */

    // Mapping from ethereum wallet to ERC725 identity
    mapping(address => address) public users;

    // Mapping from ERC725 identity to ethereum wallet
    mapping(address => address) public owners;

    /*
    * Public functions
    */

    /// @dev registerUser(): Add a user to the registry
    function registerUser(address _identity)
        public
    {
        // Only owner is allowed to register identity
        require(VerificationHolder(_identity).keyHasPurpose(keccak256(abi.encodePacked(msg.sender)), 1),
            'Account is not allowed to register identity');
        users[msg.sender] = _identity;
        owners[_identity] = msg.sender;
        emit NewUser(msg.sender, _identity);
    }

    /// @dev registerOtherAccount(): Add another user to the registry, this can only be done by registry owner
    function registerOtherAccount(address _identity, address _otherAccount) only_owner
        public
    {
        require(users[_otherAccount] == 0, 'Account is already associated with an identity');
        // Only owner is allowed to register identity
        require(VerificationHolder(_identity).keyHasPurpose(keccak256(abi.encodePacked(_otherAccount)), 1),
            'Account is not allowed to register identity');
        users[_otherAccount] = _identity;
        owners[_identity] = _otherAccount;
        emit NewUser(_otherAccount, _identity);
    }

    /// @dev clearUser(): Remove user from the registry
    function clearUser()
        public
    {
        address ownedIdentity = users[msg.sender];
        users[msg.sender] = 0;
        owners[ownedIdentity] = 0;
    }
}
