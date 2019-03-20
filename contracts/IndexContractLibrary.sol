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
pragma experimental ABIEncoderV2;   // add support for string[] return values


library IndexContractLibrary {
    enum EntryType {
        AccountId,
        GenericContract,
        IndexContract,
        ContainerContract,
        FileHash,
        Hash
    }
    struct Data {
        mapping(bytes32 => Entry) entries;
        mapping(uint256 => bytes32) entryList;
        uint256 entryCount;
    }
    struct Entry {
        string name;
        bytes32 value;
        uint256 index;
        EntryType entryType;
    }

    /// @notice remove entry from listing
    /// @param data struct with index data
    /// @param name name of entry to delete
    function removeEntry(Data storage data, string name) public {
        bytes32 hash = keccak256(name);
        uint256 index = data.entries[hash].index;
        // check, that list is not empty and entry exists (value != 0 means, it exists)
        assert(data.entryCount > 0);
        assert(data.entries[hash].value != bytes32(0));
        // delete struct values
        delete data.entries[hash];
        // move last item into deleted items positon if not deleting last item
        if (index < data.entryCount - 1) {
            // move in list and update items index value; updates index values and frees last slot
            data.entryList[index] = data.entryList[data.entryCount - 1];
            data.entries[data.entryList[index]].index = index;
        }
        delete data.entryList[--data.entryCount];
    }

    /// @notice set entry, overwrite value if name already exists
    /// @param data struct with index data
    /// @param name entry name, unique in index
    /// @param value entry value as bytes32
    function setEntry(Data storage data, string name, bytes32 value, EntryType entryType) public {
        assert(value != bytes32(0));
        bytes32 hash = keccak256(name);
        uint256 index = data.entries[hash].index;
        // only add to list if entry is new
        if (data.entries[hash].value == bytes32(0)) {
            index = data.entryCount++;
            data.entryList[index] = hash;
            data.entries[hash].index = index;
            data.entries[hash].name = name;
        }
        // update value
        data.entries[hash].value = value;
        if (data.entries[hash].entryType != entryType) {
            data.entries[hash].entryType = entryType;
        }
    }

    /// @notice get all entries as arrays of names and values
    /// @param data struct with index data
    /// @dev totalCount and offset can be used for paging
    function getEntries(Data storage data, uint256 offset) public view returns (
            string[10] names,
            bytes32[10] values,
            EntryType[10] entryTypes,
            uint256 totalCount
        ) {
        totalCount = data.entryCount;
        for (uint256 i = 0; i < 10; i++) {
             bytes32 hash = data.entryList[i + offset];
             names[i] = data.entries[hash].name;
             values[i] = data.entries[hash].value;
             entryTypes[i] = data.entries[hash].entryType;
        }
    }

    /// @notice get value of a single entry
    /// @param data struct with index data
    /// @param name name of entry to fetch
    function getEntry(Data storage data, string name) public view returns (bytes32 value, EntryType entryType) {
        return (data.entries[keccak256(name)].value, data.entries[keccak256(name)].entryType);
    }
}
