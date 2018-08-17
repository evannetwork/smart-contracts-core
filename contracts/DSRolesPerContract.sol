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

// DSRolesPerContract.sol - roled based authentication, in a one-authority-per-contract schema

// Copyright (C) 2018  Contractus

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
pragma solidity 0.4.20;

import "./ds-auth/auth.sol";


contract DSRolesPerContract is DSAuth, DSAuthority
{
    // permission config
    mapping(address=>bool) _root_users;
    mapping(address=>bytes32) _user_roles;
    mapping(bytes4=>bytes32) _capability_roles;
    mapping(bytes32=>bytes32) _operation_capability_roles;
    mapping(bytes4=>bool) _public_capabilities;
    mapping(bytes32=>bool) _public_operation_capabilities;

    // use null address to ignore code parameter but keep functions interface conform
    address public nullAddress = 0;

    // number of roles (excluding root users)
    uint8 public roleCount;
    
    // root
    uint public rootCount;
    mapping(uint=>address) public index2root;
    mapping(address=>uint) public root2index;

    // per role 
    mapping(uint8=>uint) public role2userCount;
    mapping(uint8=>mapping(uint=>address)) public role2index2user;
    mapping(uint8=>mapping(address=>uint)) public role2user2index;

    function getUserRoles(address who)
        public
        view
        returns (bytes32)
    {
        return _user_roles[who];
    }

    function getCapabilityRoles(address, bytes4 sig)
        public
        view
        returns (bytes32)
    {
        return _capability_roles[sig];
    }

    function getOperationCapabilityRoles(address, bytes32 operation)
        public
        view
        returns (bytes32)
    {
        return _operation_capability_roles[operation];
    }

    function isUserRoot(address who)
        public
        view
        returns (bool)
    {
        return _root_users[who];
    }

    function isCapabilityPublic(address, bytes4 sig)
        public
        view
        returns (bool)
    {
        return _public_capabilities[sig];
    }

    function isOperationCapabilityPublic(address, bytes32 operation)
        public
        view
        returns (bool)
    {
        return _public_operation_capabilities[operation];
    }

    function hasUserRole(address who, uint8 role)
        public
        view
        returns (bool)
    {
        bytes32 roles = getUserRoles(who);
        bytes32 shifted = bytes32(uint256(uint256(2) ** uint256(role)));
        return bytes32(0) != roles & shifted;
    }

    function canCall(address caller, address, bytes4 sig)
        public
        view
        returns (bool)
    {
        if( isUserRoot(caller) || isCapabilityPublic(nullAddress, sig) ) {
            return true;
        } else {
            var has_roles = getUserRoles(caller);
            var needs_one_of = getCapabilityRoles(nullAddress, sig);
            return bytes32(0) != has_roles & needs_one_of;
        }
    }

    function canCallOperation(address caller, address, bytes32 operation)
        public
        view
        returns (bool)
    {
        if( isUserRoot(caller) || isOperationCapabilityPublic(nullAddress, operation) ) {
            return true;
        } else {
            var has_roles = getUserRoles(caller);
            var needs_one_of = getOperationCapabilityRoles(nullAddress, operation);
            return bytes32(0) != has_roles & needs_one_of;
        }
    }

    function BITNOT(bytes32 input) internal pure returns (bytes32 output) {
        return (input ^ bytes32(uint(-1)));
    }

    function setRootUser(address who, bool enabled)
        public
        auth
    {
        // add modified user to list
        uint index;
        if (enabled && root2index[who] == 0) {
            index = ++rootCount;
            root2index[who] = index;
            index2root[index] = who;
        } else if (!enabled && root2index[who] != 0) {
            index = rootCount--;
            root2index[who] = 0;
            index2root[index] = nullAddress;
        }
        _root_users[who] = enabled;
    }

    function setUserRole(address who, uint8 role, bool enabled)
        public
        auth
    {
        // add modified user to list
        uint index;
        if (enabled && role2user2index[role][who] == 0) {
            index = ++role2userCount[role];
            role2user2index[role][who] = index;
            role2index2user[role][index] = who;
        } else if (!enabled && role2user2index[role][who] != 0) {
            uint lastMember = role2userCount[role]--;
            index = role2user2index[role][who];
            delete role2user2index[role][who];
            role2index2user[role][index] = role2index2user[role][lastMember];
            delete role2index2user[role][lastMember];
        }
        if (enabled && (role + 1) > roleCount) {
            roleCount = role + 1;
        }
        var last_roles = _user_roles[who];
        bytes32 shifted = bytes32(uint256(uint256(2) ** uint256(role)));
        if( enabled ) {
            _user_roles[who] = last_roles | shifted;
        } else {
            _user_roles[who] = last_roles & BITNOT(shifted);
        }
    }

    function setPublicCapability(address, bytes4 sig, bool enabled)
        public
        auth
    {
        _public_capabilities[sig] = enabled;
    }

    function setPublicOperationCapability(address, bytes32 operation, bool enabled)
        public
        auth
    {
        _public_operation_capabilities[operation] = enabled;
    }

    function setRoleCapability(uint8 role, address, bytes4 sig, bool enabled)
        public
        auth
    {
        var last_roles = _capability_roles[sig];
        bytes32 shifted = bytes32(uint256(uint256(2) ** uint256(role)));
        if( enabled ) {
            _capability_roles[sig] = last_roles | shifted;
        } else {
            _capability_roles[sig] = last_roles & BITNOT(shifted);
        }

    }

    function setRoleOperationCapability(uint8 role, address, bytes32 operation, bool enabled)
        public
        auth
    {
        var last_roles = _operation_capability_roles[operation];
        bytes32 shifted = bytes32(uint256(uint256(2) ** uint256(role)));
        if( enabled ) {
            _operation_capability_roles[operation] = last_roles | shifted;
        } else {
            _operation_capability_roles[operation] = last_roles & BITNOT(shifted);
        }

    }

}
