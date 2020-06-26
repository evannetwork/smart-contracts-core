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


library KeyHolderLibrary {
    event KeyAdded(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);
    event KeyRemoved(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);
    event ExecutionRequested(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);
    event ExecutionFailed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);
    event Executed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);
    event Approved(uint256 indexed executionId, bool approved);
    event ContractCreated(uint256 indexed executionId, address indexed contractId);

    struct Key {
        uint256[] purposes; //e.g., MANAGEMENT_KEY = 1, ACTION_KEY = 2, RECOVERY = 3, etc.
        uint256 keyType; // e.g. 1 = ECDSA, 2 = RSA, etc.
        bytes32 key;
    }

    struct KeyHolderData {
        uint256 executionNonce;
        mapping (bytes32 => Key) keys;
        mapping (uint256 => bytes32[])keysByPurpose;
        mapping (uint256 => Execution) executions;
    }

    struct Execution {
        address to;
        uint256 value;
        bytes data;
        bool approved;
        bool executed;
    }

    function init(address _keyHolderOwner, KeyHolderData storage _keyHolderData)
        public
    {
        bytes32 _key = keccak256(abi.encodePacked(_keyHolderOwner));
        _keyHolderData.keys[_key].key = _key;
        _keyHolderData.keys[_key].purposes.push(1);
        _keyHolderData.keys[_key].purposes.push(2);
        _keyHolderData.keys[_key].keyType = 1;
        _keyHolderData.keysByPurpose[1].push(_key);
        _keyHolderData.keysByPurpose[2].push(_key);
        emit KeyAdded(_key, 1, 1);
        emit KeyAdded(_key, 2, 1);
    }

    function getKey(KeyHolderData storage _keyHolderData, bytes32 _key)
        public
        view
        returns(uint256[] purposes, uint256 keyType, bytes32 key)
    {
        return (
            _keyHolderData.keys[_key].purposes,
            _keyHolderData.keys[_key].keyType,
            _keyHolderData.keys[_key].key
        );
    }

    function getKeyPurposes(KeyHolderData storage _keyHolderData, bytes32 _key)
        public
        view
        returns(uint256[] purposes)
    {
        return (_keyHolderData.keys[_key].purposes);
    }

    function getKeysByPurpose(KeyHolderData storage _keyHolderData, uint256 _purpose)
        public
        view
        returns(bytes32[] _keys)
    {
        return _keyHolderData.keysByPurpose[_purpose];
    }

    function addKey(KeyHolderData storage _keyHolderData, bytes32 _key, uint256 _purpose, uint256 _type)
        public
        returns (bool success)
    {
        require(_keyHolderData.keys[_key].key != _key, "Key already exists"); // Key should not already exist
        require(keyHasPurpose(_keyHolderData, keccak256(abi.encodePacked(msg.sender)), 1), "Sender does not have key management key");
        require(_purpose != 3 || _keyHolderData.keysByPurpose[3][0] == bytes32(0), "recovery key already registered");

        _keyHolderData.keys[_key].key = _key;
        _keyHolderData.keys[_key].purposes.push(_purpose);
        _keyHolderData.keys[_key].keyType = _type;

        _keyHolderData.keysByPurpose[_purpose].push(_key);

        emit KeyAdded(_key, _purpose, _type);

        return true;
    }

    function addMultiPurposeKey(KeyHolderData storage _keyHolderData, bytes32 _key, uint256[] _purposes, uint256 _type)
        public
        returns (bool success)
    {
        require(_keyHolderData.keys[_key].key != _key, "Key already exists"); // Key should not already exist
        require(keyHasPurpose(_keyHolderData, keccak256(abi.encodePacked(msg.sender)), 1), "Sender does not have key management key");

        _keyHolderData.keys[_key].key = _key;
        _keyHolderData.keys[_key].keyType = _type;
        for (uint256 i = 0; i < _purposes.length; i++) {
            uint256 purpose = _purposes[i];
            require(purpose != 3 || _keyHolderData.keysByPurpose[3][0] == bytes32(0), "recovery key already registered");
            _keyHolderData.keys[_key].purposes.push(purpose);
            _keyHolderData.keysByPurpose[purpose].push(_key[i]);
            emit KeyAdded(_key, purpose, _type);
        }

        return true;
    }

    function approve(KeyHolderData storage _keyHolderData, uint256 _id, bool _approve)
        public
        returns (bool success)
    {
        require(keyHasPurpose(_keyHolderData, keccak256(abi.encodePacked(msg.sender)), 2), "Sender does not have action key");
        return handleApprove(_keyHolderData, _id, _approve, _keyHolderData.executions[_id].data);
    }


    function approve(KeyHolderData storage _keyHolderData, uint256 _id, bool _approve, bytes _data)
        private
        returns (bool success)
    {
        require(keyHasPurpose(_keyHolderData, keccak256(abi.encodePacked(msg.sender)), 2), "Sender does not have action key");
        return handleApprove(_keyHolderData, _id, _approve, _data);
    }

    function handleApprove(KeyHolderData storage _keyHolderData, uint256 _id, bool _approve, bytes _data)
        private
        returns (bool success)
    {   
        require(!_keyHolderData.executions[_id].executed, "Already executed");
        emit Approved(_id, _approve);

        if (_approve == true) {
            _keyHolderData.executions[_id].approved = true;
            require(_keyHolderData.executions[_id].value == msg.value, "Transaction value missmatch");
            
            if (_keyHolderData.executions[_id].to != address(0)) {
                success = _keyHolderData.executions[_id].to
                  .call.value(_keyHolderData.executions[_id].value)
                  (_data, 0);
            } else {
                address addr;
                bytes memory _code = _data;
                assembly {
                    addr := create(0, add(_code, 0x20), mload(_code))
                }
                require(addr != 0, "Contract creation failed.");
                emit ContractCreated(_id, addr);
                success = true;
            }

            if (success) {
                _keyHolderData.executions[_id].executed = true;
                emit Executed(
                    _id,
                    _keyHolderData.executions[_id].to,
                    _keyHolderData.executions[_id].value,
                    _keyHolderData.executions[_id].data
                );
                return;
            } else {
                msg.sender.transfer(msg.value);
                emit ExecutionFailed(
                    _id,
                    _keyHolderData.executions[_id].to,
                    _keyHolderData.executions[_id].value,
                    _keyHolderData.executions[_id].data
                );
                return;
            }
        } else {
            _keyHolderData.executions[_id].approved = false;
        }
        return true;
    }

    function execute(KeyHolderData storage _keyHolderData, address _to, uint256 _value, bytes _data)
        public
        returns (uint256 executionId)
    {
        require(!_keyHolderData.executions[_keyHolderData.executionNonce].executed, "Already executed");
        _keyHolderData.executions[_keyHolderData.executionNonce].to = _to;
        _keyHolderData.executions[_keyHolderData.executionNonce].value = _value;
        _keyHolderData.executions[_keyHolderData.executionNonce].data = abi.encodePacked(keccak256(abi.encodePacked(_data)));

        emit ExecutionRequested(_keyHolderData.executionNonce, _to, _value, _keyHolderData.executions[_keyHolderData.executionNonce].data);

        if (keyHasPurpose(_keyHolderData, keccak256(abi.encodePacked(msg.sender)),2)) {
            approve(_keyHolderData, _keyHolderData.executionNonce, true, _data);
        }

        _keyHolderData.executionNonce++;
        return _keyHolderData.executionNonce-1;
    }

    function executeDelegated(KeyHolderData storage _keyHolderData, address _to, uint256 _value, bytes _data, bytes _signedTransactionInfo)
        public
        returns (uint256 executionId)
    {
        require(!_keyHolderData.executions[_keyHolderData.executionNonce].executed, "Already executed");
        _keyHolderData.executions[_keyHolderData.executionNonce].to = _to;
        _keyHolderData.executions[_keyHolderData.executionNonce].value = _value;
        _keyHolderData.executions[_keyHolderData.executionNonce].data = _data;

        emit ExecutionRequested(_keyHolderData.executionNonce, _to, _value, _data);
        
        // get signed message from this' address and nonce;
        // include other arguments as well to prevent using signed message for other tx
        bytes32 message = keccak256(abi.encodePacked(
            address(this),
            _keyHolderData.executionNonce,
            _to,
            _value,
            _data
        ));
        // recover _signedTransactionInfos signer
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));
        address recovered = getRecoveredAddress(_signedTransactionInfo, prefixedHash);
        // allow tx if signer === recovered
        if (keyHasPurpose(_keyHolderData, keccak256(abi.encodePacked(recovered)),2)) {
            handleApprove(_keyHolderData, _keyHolderData.executionNonce, true, _data);
        }

        _keyHolderData.executionNonce++;
        return _keyHolderData.executionNonce-1;
    }

    function removeKey(KeyHolderData storage _keyHolderData, bytes32 _key, uint256 _purpose)
        public
        returns (bool success)
    {
        require(keyHasPurpose(_keyHolderData, keccak256(abi.encodePacked(msg.sender)), 1), "Sender does not have key management key");
        require(!keyHasPurpose(_keyHolderData, _key, 3) || keccak256(abi.encodePacked(msg.sender)) == _key, "keys with purpose 3 can only be removed by themselves");

        require(_keyHolderData.keys[_key].key == _key, "No such key");
        emit KeyRemoved(_key, _purpose, _keyHolderData.keys[_key].keyType);

        // Remove purpose from key
        uint256[] storage purposes = _keyHolderData.keys[_key].purposes;
        for (uint i = 0; i < purposes.length; i++) {
            if (purposes[i] == _purpose) {
                purposes[i] = purposes[purposes.length - 1];
                delete purposes[purposes.length - 1];
                purposes.length--;
                break;
            }
        }

        // If no more purposes, delete key
        if (purposes.length == 0) {
            delete _keyHolderData.keys[_key];
        }

        // Remove key from keysByPurpose
        bytes32[] storage keys = _keyHolderData.keysByPurpose[_purpose];
        for (uint j = 0; j < keys.length; j++) {
            if (keys[j] == _key) {
                keys[j] = keys[keys.length - 1];
                delete keys[keys.length - 1];
                keys.length--;
                break;
            }
        }

        return true;
    }

    function removeMultiPurposeKey(KeyHolderData storage _keyHolderData, bytes32 _key, uint256[] _purposes)
        public
        returns (bool success)
    {
        require(keyHasPurpose(_keyHolderData, keccak256(abi.encodePacked(msg.sender)), 1), "Sender does not have key management key");
        require(!keyHasPurpose(_keyHolderData, _key, 3) || keccak256(abi.encodePacked(msg.sender)) == _key, "keys with purpose 3 can only be removed by themselves");

        require(_keyHolderData.keys[_key].key == _key, "No such key");

        // Remove purpose from key
        uint256[] storage purposes = _keyHolderData.keys[_key].purposes;
        for (uint i = 0; i < purposes.length; i++) {
            for (uint argi = 0; argi < _purposes.length; argi++) { 
                if (purposes[i] == _purposes[argi]) {
                    purposes[i] = purposes[purposes.length - 1];
                    delete purposes[purposes.length - 1];
                    purposes.length--;
                    emit KeyRemoved(_key, _purposes[argi], _keyHolderData.keys[_key].keyType);
                    break;
                }
            }
        }

        // If no more purposes, delete key
        if (purposes.length == 0) {
            delete _keyHolderData.keys[_key];
        }

        // Remove key from keysByPurpose
        for (uint argj = 0; argj < purposes.length; argj++) { 
            bytes32[] storage keys = _keyHolderData.keysByPurpose[_purposes[argj]];
            for (uint j = 0; j < keys.length; j++) {
                if (keys[j] == _key) {
                    keys[j] = keys[keys.length - 1];
                    delete keys[keys.length - 1];
                    keys.length--;
                    break;
                }
            }
        }

        return true;
    }

    function keyHasPurpose(KeyHolderData storage _keyHolderData, bytes32 _key, uint256 _purpose)
        public
        view
        returns(bool result)
    {
        bool isThere;
        if (_keyHolderData.keys[_key].key == 0) {
            return false;
        }

        uint256[] storage purposes = _keyHolderData.keys[_key].purposes;
        for (uint i = 0; i < purposes.length; i++) {
            if (purposes[i] == _purpose) {
                isThere = true;
                break;
            }
        }
        return isThere;
    }

    function getRecoveredAddress(bytes sig, bytes32 dataHash)
        public
        pure
        returns (address addr)
    {
        bytes32 ra;
        bytes32 sa;
        uint8 va;

        // Check the signature length
        if (sig.length != 65) {
            return (0);
        }

        // Divide the signature in r, s and v variables
        assembly {
            ra := mload(add(sig, 32))
            sa := mload(add(sig, 64))
            va := byte(0, mload(add(sig, 96)))
        }

        if (va < 27) {
            va += 27;
        }

        address recoveredAddress = ecrecover(dataHash, va, ra, sa);

        return (recoveredAddress);
    }
}
