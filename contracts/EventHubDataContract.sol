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

pragma solidity 0.4.20;


/// @title triggering data contract events
/// @author contractus GmbH
/// @notice used as a base class for EventHub
contract EventHubDataContract {

    event DataContractEvent(
        address indexed sender,
        bytes32 indexed propertyType,
        bytes32[] indexed propertyKeys,
        bytes32 updateType,
        uint256 updated
    );

    /// @notice send data contract from this event hub
    /// @param propertyType type of property that was updated (entry / list entry)
    /// @param propertyKeys name of property that was updated
    /// @param updateType type update (set / remove)
    /// @param updated number of updated elments in addListEntry, index of removed entry in removeListEntry
    function sendDataContractEvent(bytes32 propertyType, bytes32[] propertyKeys, bytes32 updateType, uint256 updated) public {
        DataContractEvent(msg.sender, propertyType, propertyKeys, updateType, updated);
    }
}
