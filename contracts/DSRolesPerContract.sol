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
pragma solidity ^0.4.24;
 
import "./ds-auth/auth.sol";
import "./DSRolesPerContractLibrary.sol";
 

contract DSRolesPerContract is DSAuth, DSAuthority
{
    DSRolesPerContractLibrary.Data data;
    
    // getter all the things
    function roleCount() public view returns(uint8) { return data.roleCount; }
    function role2userCount(uint8 a) public view returns(uint) { return data.role2userCount[a]; }
    function role2index2user(uint8 a, uint b) public view returns(address) { return data.role2index2user[a][b]; }
    
    function rootCount() public view returns(uint) { return data.rootCount; }
    function index2root(uint a) public view returns(address) { return data.index2root[a]; }
 
    function getUserRoles(address who)
        public
        view
        returns (bytes32)
    {
        return data._user_roles[who];
    }
 
    function getCapabilityRoles(address targetAddress, bytes4 sig)
        public
        view
        returns (bytes32)
    {
        return data._capability_roles[sig];
    }
 
    function getOperationCapabilityRoles(address targetAddress, bytes32 operation)
        public
        view
        returns (bytes32)
    {
        return data._operation_capability_roles[operation];
    }
 
    function isUserRoot(address who)
        public
        view
        returns (bool)
    {
        return data._root_users[who];
    }
 
    function isCapabilityPublic(address targetAddress, bytes4 sig)
        public
        view
        returns (bool)
    {
        return data._public_capabilities[sig];
    }
 
    function isOperationCapabilityPublic(address targetAddress, bytes32 operation)
        public
        view
        returns (bool)
    {
        return data._public_operation_capabilities[operation];
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
 
    function canCall(address caller, address targetAddress, bytes4 sig)
        public
        view
        returns (bool)
    {
        if (isUserRoot(caller) || isCapabilityPublic(targetAddress, sig) ) {
            return true;
        } else {
            bytes32 has_roles = getUserRoles(caller);
            bytes32 needs_one_of = getCapabilityRoles(targetAddress, sig);
            return bytes32(0) != has_roles & needs_one_of;
        }
    }
 
    function canCallOperation(address caller, address targetAddress, bytes32 operation)
        public
        view
        returns (bool)
    {
        if (isUserRoot(caller) || isOperationCapabilityPublic(targetAddress, operation) ) {
            return true;
        } else {
            bytes32 has_roles = getUserRoles(caller);
            bytes32 needs_one_of = getOperationCapabilityRoles(targetAddress, operation);
            return bytes32(0) != has_roles & needs_one_of;
        }
    }
 
    function setRootUser(address who, bool enabled)
        public
        auth
    {
        DSRolesPerContractLibrary.setRootUser(data, who, enabled);
    }
 
    function setUserRole(address who, uint8 role, bool enabled)
        public
        auth
    {
        DSRolesPerContractLibrary.setUserRole(data, who, role, enabled);
    }
 
    function setPublicCapability(address targetAddress, bytes4 sig, bool enabled)
        public
        auth
    {
        data._public_capabilities[sig] = enabled;
    }
 
    function setPublicOperationCapability(address targetAddress, bytes32 operation, bool enabled)
        public
        auth
    {
        data._public_operation_capabilities[operation] = enabled;
    }
 
    function setRoleCapabilities(uint8[] roles, bytes4[] sigs, bool enabled)
        public
        auth
    {
        require(roles.length == sigs.length);
        for (uint256 i = 0; i < roles.length; i++) {
            bytes32 last_roles = data._capability_roles[sigs[i]];
            bytes32 shifted = bytes32(uint256(uint256(2) ** uint256(roles[i])));
            if( enabled ) {
                data._capability_roles[sigs[i]] = last_roles | shifted;
            } else {
                data._capability_roles[sigs[i]] = last_roles & BITNOT(shifted);
            }
        }
    }
 
    function setRoleCapability(uint8 role, address targetAddress, bytes4 sig, bool enabled)
        public
        auth
    {
        bytes32 last_roles = data._capability_roles[sig];
        bytes32 shifted = bytes32(uint256(uint256(2) ** uint256(role)));
        if( enabled ) {
            data._capability_roles[sig] = last_roles | shifted;
        } else {
            data._capability_roles[sig] = last_roles & BITNOT(shifted);
        }
    }
 
    function setRoleOperationCapabilities(uint8[] roles, bytes32[] operations, bool enabled)
        public
        auth
    {
        require(roles.length == operations.length);
        for (uint256 i = 0; i < roles.length; i++) {
            bytes32 last_roles = data._operation_capability_roles[operations[i]];
            bytes32 shifted = bytes32(uint256(uint256(2) ** uint256(roles[i])));
            if( enabled ) {
                data._operation_capability_roles[operations[i]] = last_roles | shifted;
            } else {
                data._operation_capability_roles[operations[i]] = last_roles & BITNOT(shifted);
            }
        }
    }
 
    function setRoleOperationCapability(uint8 role, address targetAddress, bytes32 operation, bool enabled)
        public
        auth
    {
        bytes32 last_roles = data._operation_capability_roles[operation];
        bytes32 shifted = bytes32(uint256(uint256(2) ** uint256(role)));
        if( enabled ) {
            data._operation_capability_roles[operation] = last_roles | shifted;
        } else {
            data._operation_capability_roles[operation] = last_roles & BITNOT(shifted);
        }
    }
    
    function BITNOT(bytes32 input)
        private pure returns (bytes32 output) {
        return (input ^ bytes32(uint(-1)));
    }
 
}
 