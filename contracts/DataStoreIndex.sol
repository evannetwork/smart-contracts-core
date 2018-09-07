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

pragma solidity 0.4.24;

import "./DataStoreMap.sol";
import "./DataStoreIndexInterface.sol";
import "./DataStoreList.sol";

contract DataStoreIndex is DataStoreIndexInterface, OwnedModerated {
    uint public VERSION_ID = 1;
    DataStoreMap containers;
    uint lastModified;

    constructor(DataStoreMap data) public {
        // --> upgrade
        containers = data;
        lastModified = now;
    }

    function containerGet(bytes32 key) public constant returns (bytes32) {
        return containers.get(key);
    }

    function containerHas(bytes32 key) public constant returns (bool) {
        return containers.has(key);
    }

    function containerRemove(bytes32 key) public only_owner_or_moderator {
        containers.remove(key);
    }

    function containerSet(bytes32 key, bytes32 value) public only_owner_or_moderator {
        containers.set(key, value);
    }

    function indexGet(bytes32 key) public constant returns (DataStoreIndexInterface) {
        DataStoreIndexInterface index = DataStoreIndexInterface(address(containers.get(key)));
        return index;
    }

    function indexMakeModerator(bytes32 key) public only_owner_or_moderator {
        DataStoreIndex index = DataStoreIndex(address(containers.get(key)));
        index.addModerator(msg.sender);
    }

    function listEntryAdd(bytes32 containerName, bytes32 value) public only_owner_or_moderator {
        DataStoreList list = listEnsure(containerName);
        list.add(value);
        lastModified = now;
    }

    function listEntryRemove(bytes32 containerNames, uint index) public only_owner_or_moderator {
        DataStoreList(getContainerAddress(containerNames)).remove(index);
        lastModified = now;
    }

    function listEntryUpdate(bytes32 containerNames, uint index, bytes32 value) public only_owner_or_moderator {
        DataStoreList(getContainerAddress(containerNames)).update(index, value);
        lastModified = now;
    }

    function listEntryGet(bytes32 containerName, uint index) public constant returns(bytes32) {
        return DataStoreList(getContainerAddress(containerName)).get(index);
    }

    function listIndexOf(bytes32 containerName, bytes32 value) public constant returns(uint index, bool okay) {
        address listAddress = getContainerAddress(containerName);
        if (listAddress != 0x0) {
          return DataStoreList(listAddress).indexOf(value);
        }
    }

    function listLastModified(bytes32 containerName) public constant returns(uint) {
        return DataStoreList(getContainerAddress(containerName)).lastModified();
    }

    function listLength(bytes32 containerName) public constant returns(uint) {
        address addr = getContainerAddress(containerName);
        if (addr == 0x0) {
            return 0;
        } else {
            return DataStoreList(addr).length();
        }
    }

    function listEnsure(bytes32 containerName) private returns(DataStoreList) {
        DataStoreList list;
        address listAddress = address(containers.get(containerName));
        if (listAddress == 0x0) {
            list = new DataStoreList();
            containers.set(containerName, bytes32(address(list)));
            lastModified = now;
        } else {
            list = DataStoreList(listAddress);
        }
        return list;
    }

    function getContainerAddress(bytes32 containerName) private constant returns(address) {
        return address(containers.get(containerName));
    }

}
