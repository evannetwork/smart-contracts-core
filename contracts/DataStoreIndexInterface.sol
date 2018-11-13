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


interface DataStoreIndexInterface {
    function containerGet(bytes32 key) external constant returns (bytes32);

    function containerHas(bytes32 key) external constant returns (bool);

    function containerRemove(bytes32 key) external;

    function containerSet(bytes32 key, bytes32 value) external;

    function indexGet(bytes32 key) external constant returns (DataStoreIndexInterface);

    function indexMakeModerator(bytes32 key) external;

    function listEntryAdd(bytes32 containerName, bytes32 value) external;

    function listEntryRemove(bytes32 containerNames, uint index) external;

    function listEntryUpdate(bytes32 containerNames, uint index, bytes32 value) external;

    function listEntryGet(bytes32 containerName, uint index) external constant returns(bytes32);

    function listIndexOf(bytes32 containerName, bytes32 value) external constant returns(uint index, bool okay);

    function listLastModified(bytes32 containerName) external constant returns(uint);

    function listLength(bytes32 containerName) external constant returns(uint);
}
