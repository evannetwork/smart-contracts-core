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

import "./DataStoreIndexInterface.sol";


/** @title Profile Index Contract - stores all personal profile containers */
interface ProfileIndexInterface {
    /**@dev tries to get the ipld hash for a given label
     * @param account accountid for profile
     * @return hash of the label
     */
    function getProfile(address account) external constant returns (address);

    /**@dev transfers ownership of storage to another contract
     * @param newProfileIndex new profile index to hand over storage to
     */
    function migrateTo(address newProfileIndex) external;

    /**@dev sets a hash for a given container label
     * @param _address contract address that holds the information.
     */
    function setMyProfile(address _address) external;

    /**@dev sets a profile for a given account
     * @param account account to set profile for
     * @param profile contract address that holds the information.
     */
    function setProfile(address account, address profile) external;

    /**@dev returns the global db for migration purposes
     * @return global db
     */    
    function getStorage() external constant returns (DataStoreIndexInterface);
}
