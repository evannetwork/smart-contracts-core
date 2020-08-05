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

import "./ERC725.sol";
import "./KeyHolderLibrary.sol";


contract KeyHolder is ERC725 {
    uint256 public VERSION_ID = 1;
    KeyHolderLibrary.KeyHolderData keyHolderData;

    constructor(address _keyHolderOwner) public {
        KeyHolderLibrary.init(_keyHolderOwner, keyHolderData);
    }

    function () public payable {
        // accept funds
    }

    function getExecutionNonce()
        public
        view
        returns(uint256)
    {
        return keyHolderData.executionNonce;
    }

    function getKey(bytes32 _key)
        public
        view
        returns(uint256[] purposes, uint256 keyType, bytes32 key)
    {
        return KeyHolderLibrary.getKey(keyHolderData, _key);
    }

    function getKeyPurposes(bytes32 _key)
        public
        view
        returns(uint256[] purposes)
    {
        return KeyHolderLibrary.getKeyPurposes(keyHolderData, _key);
    }

    function getKeysByPurpose(uint256 _purpose)
        public
        view
        returns(bytes32[] _keys)
    {
        return KeyHolderLibrary.getKeysByPurpose(keyHolderData, _purpose);
    }

    function addKey(bytes32 _key, uint256 _purpose, uint256 _type)
        public
        returns (bool success)
    {
        return KeyHolderLibrary.addKey(keyHolderData, _key, _purpose, _type);
    }

    function addMultiPurposeKey(bytes32 _key, uint256[] _purposes, uint256 _type)
        public
        returns (bool success)
    {
        return KeyHolderLibrary.addMultiPurposeKey(keyHolderData, _key, _purposes, _type);
    }

    function approve(uint256 _id, bool _approve)
        public
        returns (bool success)
    {
        return KeyHolderLibrary.approve(keyHolderData, _id, _approve);
    }

    function execute(address _to, uint256 _value, bytes _data)
        public
        payable
        returns (uint256 executionId)
    {
        return KeyHolderLibrary.execute(keyHolderData, _to, _value, _data);
    }

    function executeDelegated(address _to, uint256 _value, bytes _data, bytes _signedTransactionInfo)
        public
        payable
        returns (uint256 executionId)
    {
        return KeyHolderLibrary.executeDelegated(keyHolderData, _to, _value, _data, _signedTransactionInfo);
    }

    function removeKey(bytes32 _key, uint256 _purpose)
        public
        returns (bool success)
    {
        return KeyHolderLibrary.removeKey(keyHolderData, _key, _purpose);
    }

    function removeMultiPurposeKey(bytes32 _key, uint256[] _purposes)
        public
        returns (bool success)
    {
        return KeyHolderLibrary.removeMultiPurposeKey(keyHolderData, _key, _purposes);
    }

    function keyHasPurpose(bytes32 _key, uint256 _purpose)
        public
        view
        returns(bool exists)
    {
        return KeyHolderLibrary.keyHasPurpose(keyHolderData, _key, _purpose);
    }
}
