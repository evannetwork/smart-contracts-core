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

import "./ds-auth/auth.sol";
import "./Described.sol";
import "./IndexContractLibrary.sol";

/// @title index contract, lists entries (bytes32 values)
/// @author evan GmbH
contract IndexContract is DSAuth, Described {
    IndexContractLibrary.Data iclData;

    // /// @notice create new IndexContractInstance
    // /// @param description bytes32 hash for contract description
    // constructor(bytes32 description) public {
    //     setContractDescription(description);
    // }

    /// @notice remove entry from listing
    /// @param name name of entry to delete
    function removeEntry(string name) public auth {
        IndexContractLibrary.removeEntry(iclData, name);
    }

    /// @notice set entry, overwrite value if name already exists
    /// @param name entry name, unique in index
    /// @param value entry value as bytes32
    function setEntry(string name, bytes32 value) public auth {
        IndexContractLibrary.setEntry(iclData, name, value);
    }

    /// @notice get all entries as arrays of names and values
    /// @dev totalCount and offset can be used for paging
    function getEntries(uint256 offset) public view returns (
            string[10] names,
            bytes32[10] values,
            uint256 totalCount
        ) {
        return IndexContractLibrary.getEntries(iclData, offset);
    }

    /// @notice get value of a single entry
    /// @param name name of entry to fetch
    function getEntry(string name) public view returns (bytes32) {
        return IndexContractLibrary.getEntry(iclData, name);
    }

    /*
    /// @notice retrieve a single entry from a mapping
    /// @param mappingHash keccak256 hash of the mapping name
    /// @param key keccak256 hash of the mappings entry/property name
    /// @return value for this mapping entry
    function getMappingValue(bytes32 mappingHash, bytes32 key) public constant returns(bytes32) {
        // placeholder for copying comments
        return 0;
    }
    */
}
