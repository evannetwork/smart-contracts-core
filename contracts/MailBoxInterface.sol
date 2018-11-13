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

import "./Core.sol";
import "./EnsReader.sol";
import "./DataStoreIndex.sol";


/** @title MailBox Contract - stores messages and replies */
contract MailBoxInterface is Owned, EnsReader {

    DataStoreIndex public db;

    /**@dev this contract can receive funds (for migrating funds to a new mailbox)
     */
    function() public payable { }

    /**@dev returns the mailbox from the sender
     * @return address of the datastorelist
     */
    function getMyReceivedMails() public constant returns (bytes32);

    /**@dev returns the mailbox from the sender
     * @return address of the datastorelist
     */
    function getMySentMails() public constant returns (bytes32);

    /**@dev returns a specific mail 
     *
     * @param mailId id of the target mail
     * @return hash of the mail content and the mail sender
     */
    function getMail(uint256 mailId) public constant returns (bytes32 data, bytes32 sender);

    /**@dev returns all answers for a specific mail
     *
     * @param mailId id of the target mail
     * @return address of the datastorelist with all answers
     */
    function getAnswersForMail(uint256 mailId) public constant returns (bytes32);

    /**@dev transfers ownership of storage to another contract
     * @param newProfileIndex new profile index to hand over storage to
     */
    function migrateTo(address newProfileIndex) public;

    /**@dev sends a mail to given users
     *
     * @param recipients array of recipient addresses
     * @param mailHash hash of the mail content
     */
    function sendMail(address[] recipients, bytes32 mailHash) public payable;

    /**@dev sends an anwser to given users
     *
     * @param recipients array of recipient addresses
     * @param mailHash hash of the mail content
     */
    function sendAnswer(address[] recipients, bytes32 mailHash, uint256 mailId) public payable;

    /**@dev get funds from mail or answer and transfer to account
     *
     * @param mailId id a mail
     * @param recipient account, that receives withdrawed funds
     */
    function withdrawFromMail(uint256 mailId, address recipient) public;

    /**@dev get check balance of a mail or answer
     *
     * @param mailId id of the mail to check
     */
    function getBalanceFromMail(uint256 mailId) public constant returns(uint256);

    /**@dev returns the global db for migration purposes
     * @return global db
     */    
    function getStorage() public constant returns (DataStoreIndex);
}
