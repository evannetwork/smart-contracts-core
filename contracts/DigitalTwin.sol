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
import "./DigitalTwinLibrary.sol";

/// @title digital twin contract, lists entries (bytes32 values)
/// @author evan GmbH
contract DigitalTwin is DSAuth, Described {
    DigitalTwinLibrary.Data iclData;

    /// @notice remove entry from listing
    /// @param name name of entry to delete
    function removeEntry(string name) public auth {
        DigitalTwinLibrary.removeEntry(iclData, name);
    }

    /// @notice set entry, overwrite value if name already exists
    /// @param name entry name, unique in index
    /// @param value entry value as bytes32
    function setEntry(string name, bytes32 value, DigitalTwinLibrary.EntryType entryType) public auth {
        DigitalTwinLibrary.setEntry(iclData, name, value, entryType);
    }

    /// @notice get all entries as arrays of names and values
    /// @dev totalCount and offset can be used for paging
    function getEntries(uint256 offset) public view returns (
            string[10] names,
            bytes32[10] values,
            DigitalTwinLibrary.EntryType[10] entryTypes,
            uint256 totalCount
        ) {
        return DigitalTwinLibrary.getEntries(iclData, offset);
    }

    /// @notice get value of a single entry
    /// @param name name of entry to fetch
    function getEntry(string name) public view returns (bytes32 value, DigitalTwinLibrary.EntryType entryType) {
        return DigitalTwinLibrary.getEntry(iclData, name);
    }
}
