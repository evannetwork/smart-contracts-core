pragma solidity ^0.4.24;
 

library DSRolesPerContractLibrary {
    struct Data {
        // permission config
        mapping(address=>bool) _root_users;
        mapping(address=>bytes32) _user_roles;
        mapping(bytes4=>bytes32) _capability_roles;
        mapping(bytes32=>bytes32) _operation_capability_roles;
        mapping(bytes4=>bool) _public_capabilities;
        mapping(bytes32=>bool) _public_operation_capabilities;
    
        // use null address to ignore code parameter but keep functions interface conform
        address nullAddress;
    
        // number of roles (excluding root users)
        uint8 roleCount;
        
        // root
        uint rootCount;
        mapping(uint=>address) index2root;
        mapping(address=>uint) root2index;
        // per role 
        mapping(uint8=>uint) role2userCount;
        mapping(uint8=>mapping(uint=>address)) role2index2user;
        mapping(uint8=>mapping(address=>uint)) role2user2index;
    }
 
    function setRootUser(Data storage data, address who, bool enabled)
        public
    {
        // add modified user to list
        uint index;
        if (enabled && data.root2index[who] == 0) {
            index = ++data.rootCount;
            data.root2index[who] = index;
            data.index2root[index] = who;
        } else if (!enabled && data.root2index[who] != 0) {
            index = data.rootCount--;
            data.root2index[who] = 0;
            data.index2root[index] = address(0);
        }
        data._root_users[who] = enabled;
    }
    
 
    function setUserRole(Data storage data, address who, uint8 role, bool enabled)
        public
    {
        // add modified user to list
        uint index;
        if (enabled && data.role2user2index[role][who] == 0) {
            index = ++data.role2userCount[role];
            data.role2user2index[role][who] = index;
            data.role2index2user[role][index] = who;
        } else if (!enabled && data.role2user2index[role][who] != 0) {
            uint lastMember = data.role2userCount[role]--;
            index = data.role2user2index[role][who];
            delete data.role2user2index[role][who];
            address memberToMove = data.role2index2user[role][lastMember];
            // move member to new index
            data.role2index2user[role][index] = memberToMove;
            // update index for this member
            data.role2user2index[role][memberToMove] = index;
            delete data.role2index2user[role][lastMember];
        }
        if (enabled && (role + 1) > data.roleCount) {
            data.roleCount = role + 1;
        }
        bytes32 last_roles = data._user_roles[who];
        bytes32 shifted = bytes32(uint256(uint256(2) ** uint256(role)));
        if (enabled ) {
            data._user_roles[who] = last_roles | shifted;
        } else {
            data._user_roles[who] = last_roles & BITNOT(shifted);
        }
    }
    
    
    
    
    
    
    
    function setRoleCapability(Data storage data, uint8 role, address, bytes4 sig, bool enabled)
        private
    {
        bytes32 last_roles = data._capability_roles[sig];
        bytes32 shifted = bytes32(uint256(uint256(2) ** uint256(role)));
        if( enabled ) {
            data._capability_roles[sig] = last_roles | shifted;
        } else {
            data._capability_roles[sig] = last_roles & BITNOT(shifted);
        }
 
    }
 
    function setRoleOperationCapability(Data storage data, uint8 role, address, bytes32 operation, bool enabled)
        private
    {
        bytes32 last_roles = data._operation_capability_roles[operation];
        bytes32 shifted = bytes32(uint256(uint256(2) ** uint256(role)));
        if( enabled ) {
            data._operation_capability_roles[operation] = last_roles | shifted;
        } else {
            data._operation_capability_roles[operation] = last_roles & BITNOT(shifted);
        }
 
    }
    
    function canCall(Data storage data, address caller, address targetAddress, bytes4 sig)
        private
        view
        returns (bool)
    {
        if (isUserRoot(data, caller) || isCapabilityPublic(data, targetAddress, sig) ) {
            return true;
        } else {
            bytes32 has_roles = getUserRoles(data, caller);
            bytes32 needs_one_of = getCapabilityRoles(data, targetAddress, sig);
            return bytes32(0) != has_roles & needs_one_of;
        }
    }
    
    function canCallOperation(Data storage data, address caller, address targetAddress, bytes32 operation)
        private
        view
        returns (bool)
    {
        if (isUserRoot(data, caller) || isOperationCapabilityPublic(data, targetAddress, operation) ) {
            return true;
        } else {
            bytes32 has_roles = getUserRoles(data, caller);
            bytes32 needs_one_of = getOperationCapabilityRoles(data, targetAddress, operation);
            return bytes32(0) != has_roles & needs_one_of;
        }
    }
    
    function hasUserRole(Data storage data, address who, uint8 role)
        private
        view
        returns (bool)
    {
        bytes32 roles = getUserRoles(data, who);
        bytes32 shifted = bytes32(uint256(uint256(2) ** uint256(role)));
        return bytes32(0) != roles & shifted;
    }
    
    function getUserRoles(Data storage data, address who)
        private
        view
        returns (bytes32)
    {
        return data._user_roles[who];
    }
    
    function getCapabilityRoles(Data storage data, address, bytes4 sig)
        private
        view
        returns (bytes32)
    {
        return data._capability_roles[sig];
    }
    
    function getOperationCapabilityRoles(Data storage data, address, bytes32 operation)
        private
        view
        returns (bytes32)
    {
        return data._operation_capability_roles[operation];
    }
    
    function isUserRoot(Data storage data, address who)
        private
        view
        returns (bool)
    {
        return data._root_users[who];
    }
    
    function isCapabilityPublic(Data storage data, address, bytes4 sig)
        private
        view
        returns (bool)
    {
        return data._public_capabilities[sig];
    }
 
    function isOperationCapabilityPublic(Data storage data, address, bytes32 operation)
        private
        view
        returns (bool)
    {
        return data._public_operation_capabilities[operation];
    }
    
    function BITNOT(bytes32 input)
        private pure returns (bytes32 output) {
        return (input ^ bytes32(uint(-1)));
    }
 
    function setPublicCapability(Data storage data, address, bytes4 sig, bool enabled)
        private
    {
        data._public_capabilities[sig] = enabled;
    }
 
    function setPublicOperationCapability(Data storage data, address, bytes32 operation, bool enabled)
        private
    {
        data._public_operation_capabilities[operation] = enabled;
    }
}