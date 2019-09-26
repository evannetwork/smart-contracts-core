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

const smartContractsCore = require('../index')
const  Web3 = require('web3')
const Tx = require('ethereumjs-tx')


let account;
let key;
let gasPrice;
let gasLimit;
let solc = new smartContractsCore.Solc({
  config: { compileContracts: true, },
  log: console.log,
})

async function executeTransaction (web3, signedTx) {
  return new Promise((s, r) => {  
    let resolved = false;
    web3.eth.sendSignedTransaction(signedTx)
      .on('transactionHash', async (txHash) => {
        if (resolved) {
          // return if already resolved
          return;
        }
        const receipt = await web3.eth.getTransactionReceipt(txHash);

        if (resolved) {
          // return if resolved while waiting for getTransactionReceipt
          return;
        }
        if (receipt) {
          resolved = true;
          s(receipt);
        }
      })
      .on('receipt', (receipt) => {
        if (resolved) {
          // return if already resolved
          return;
        }
        resolved = true;
        s(null, receipt); })
      .on('error', (error) => { r(error); })
  });
}

async function deployLibrary(_contractName, contracts, nonce) {
  const [ _, contractName ] = /:(.*)$/.exec(_contractName);
  const bytecode = contracts[contractName].bytecode

  const tra = {
    data: `0x${bytecode}`,
    from: account,
    gasLimit,
    gasPrice,
    nonce: `0x${nonce.toString(16)}`,
    value: 0,
  }

  const tx = new Tx(tra)
  tx.sign(key)

  const stx = tx.serialize()
  const web3 = new Web3(
    process.env.CHAIN_ENDPOINT || 'wss://testcore.evan.network/ws',
    null,
    { transactionConfirmationBlocks: 1 },
  );
  const result = await executeTransaction(web3, '0x' + stx.toString('hex'))
  console.dir((({ contractAddress, gasUsed, status }) =>
    ({ contractName, contractAddress, gasUsed, status }))(result))
  return result.contractAddress
}

(async () => {
  console.group('compiling contracts')
  try {
    await solc.ensureCompiled()
    let contracts = await solc.getContracts(null, true)
    const toDeploys = solc.getLibrariesToRedeploy()
    if (toDeploys && toDeploys.length > 0) {
      console.log(`deploying: ${toDeploys.join(', ')}`)
      if (!process.env.ACCOUNT_ID || !process.env.PRIVATE_KEY) {
        throw Error('ACCOUNT_ID or PRIVATE_KEY unset, set both as environment variables')
      }

      account = process.env.ACCOUNT_ID
      key = new Buffer(process.env.PRIVATE_KEY, 'hex')
      gasPrice = process.env.GAS_PRICE || '0x2e90edd000'  // 200GWei
      gasLimit = '0x7a1200'  // 8000000
      const libraryUpdates = {}
      const web3 = new Web3(
        process.env.CHAIN_ENDPOINT || 'wss://testcore.evan.network/ws', null, { transactionConfirmationBlocks: 1 });
      let nonce = await web3.eth.getTransactionCount(account)
      for (let toDeploy of toDeploys) {
        // deploy contract
        const deployed = await deployLibrary(toDeploy, contracts, nonce++)
        // update compiled contracts
        const toLink = { [toDeploy]: deployed }
        solc.linkLibraries(contracts, toLink)
        Object.assign(libraryUpdates, toLink)
        // re-compile contracts and update compiled files
        await solc.ensureCompiled()
        contracts = await solc.getContracts(null, true)
        // (if required, repeat until all contracts have been included in contracts file)
      }
      console.log('deployed new libraries, make sure to update config accordingly')
      console.dir(libraryUpdates)
    }
  } catch(ex) {
    console.dir(ex)
    console.error(`building contracts failed: ${ex.msg || ex}${ex.stack ? '; ' + ex.stack : ''}`)
  }
  console.groupEnd('compiling contracts')
  console.log('done')
  process.exit()
})()
