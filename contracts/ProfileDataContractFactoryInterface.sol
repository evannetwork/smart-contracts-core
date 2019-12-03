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

/// @title Interface contract for creating new profiles via factory
/// @author evan GmbH
/// @dev list of entry names and list of list names, which are to be configured to be accessible by respective groups
contract ProfileDataContractFactoryInterface {
  uint public VERSION_ID;

  event ContractCreated(bytes32 contractInfo, address newAddress);

  /// @notice create new DataContract to be used as a profile
  /// @param businessCenter if required, dedicated business center for profile
  /// @param provider owner of new profile
  /// @param contractDescription DBCP definition of the contract
  /// @param ensAddress address of the ENS contract
  /// @param entries name of entries in profile to be accessible by respective groups
  /// @param lists name of lists in profile to be accessible by respective groups
  /// @return address of new profile
  function createContract(
      address businessCenter,
      address provider,
      bytes32 contractDescription,
      address ensAddress,
      bytes32[] entries,
      bytes32[] lists
  ) public returns (address);
}
