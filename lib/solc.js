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

const {promisify} = require('util')
const fs = require('fs')
const path = require('path')

const findup = require('findup-sync')
const rread = require('fs-readdir-recursive')
const solc = require('solc')
const linker = require('solc/linker')

const errorPattern = /^.*error:/i;
const filenamePattern = /^([^:]+)(?:\s|.)*$/;

// default paths
const solPath = `../contracts`
const compiledPath = `${__dirname}/${solPath}`

const compiledFile = 'compiled.json'
const compiledJSFile = 'compiled.js'

// bytecodes for a smaller file size, to load the smart contracts faster within the ui, gets deleted
// all contracts in this list will include bytecodes also for the ui build
const uiAllowedByteCodes = [
  'verifications/KeyHolderLibrary.sol:KeyHolderLibrary',
  'verifications/VerificationHolder.sol:VerificationHolder',
];

// dependencies between libraries
const libraryDependencies = {
  'verifications/VerificationHolderLibrary.sol:VerificationHolderLibrary': ['verifications/KeyHolderLibrary.sol:KeyHolderLibrary'],
  'BaseContractZeroLibrary.sol:BaseContractZeroLibrary': ['DSRolesPerContractLibrary.sol:DSRolesPerContractLibrary'],
  'DataContractLibrary.sol:DataContractLibrary': ['DSRolesPerContractLibrary.sol:DSRolesPerContractLibrary'],
};

// list of known and deployed smart contract libraries
// setting a value to a falsy value will depeloy it and its dependants
const librariesAddresses = {
  'verifications/KeyHolderLibrary.sol:KeyHolderLibrary': '0xFDb2b28f481D9FEbB55Cea18131C8d96b18D16bB',
  'verifications/VerificationHolderLibrary.sol:VerificationHolderLibrary': '0xb1621be2ef1F2dC5153B2487600CcC1E4Fa7ee27',
  'verifications/VerificationsRegistryLibrary.sol:VerificationsRegistryLibrary': '0x53943BD308f3CB0E79Cb4811288dB1AB2AaFa6b2',
  'DSRolesPerContractLibrary.sol:DSRolesPerContractLibrary': '0x1DB5f4b029B50dD68065c46717075C2Cf4CaaBb4',
  'BaseContractZeroLibrary.sol:BaseContractZeroLibrary': '0x48826Db0Dd98085c78d49bFFabbabc9DE302Ce94',
  'DataContractLibrary.sol:DataContractLibrary': '0xb7fAb2190Eee66476D98E58be603CF99Ec8b27c3',
};

class Solc {
  /**
   * creates new Solc instance
   *
   * @param      {any}  options  supports properties: compileContracts, destinationPath
   */
  constructor(options) {
    this.log = options.log;
    this.config = Object.assign({}, options.config);
    this.config.uiAllowedByteCodes = uiAllowedByteCodes.concat(options.uiAllowedByteCodes || []);
    this.config.libraryDependencies = Object.assign({}, libraryDependencies, options.libraryDependencies);
    this.config.librariesAddresses = Object.assign({}, librariesAddresses, options.librariesAddresses);

    // when using the constructor it is possible to search for the best preset destiantionPath
    // the directory must exist, or the default is used
    if(!this.config.destinationPath ||
       typeof this.config.destinationPath === 'string' &&
       !fs.existsSync(path.resolve( this.config.destinationPath, compiledFile)))
      this.config.destinationPath = compiledPath
    else if(Array.isArray(this.config.destinationPath)) {
      for(let d of this.config.destinationPath) {
        if(fs.existsSync(path.resolve( d, compiledFile))) {
          this.config.destinationPath = d
          break;
        }
      }
      if (typeof this.config.destinationPath !== 'string') {
        this.config.destinationPath = compiledPath;
      }
    }
  }

  /**
   * compile contracts
   *
   * @param      {any}           src_tree  object with folders and their file list as key, value
   * @return     {Promise<any>}  object with fn (.js content) and .jsfn (.json content)
   */
  async compileContracts(src_tree, dst) {
    this.log('Compile Solidity contracts...')
    const solFiles = {}

    for(let dir in src_tree) {
      for(let f of src_tree[dir]) {
        if (f.toLowerCase().endsWith('.sol')) {
          if(f in solFiles) this.log(`${f} is duplicate filename`);
          solFiles[f] = (promisify(fs.readFile)(path.resolve(dir, f), 'utf8'));
        }
      }
    }

    await Promise.all(Object.values(solFiles))

    for(let f in solFiles) solFiles[f] = await solFiles[f]

    const output = solc.compile({ sources: solFiles, }, 1) // 1 activates the optimizer

    // drop warnings
    const errors = output.errors ? output.errors.filter(line => errorPattern.test(line)) : null;
    if (errors && errors.length) {
      this.log('Contract compile error: \n' + errors, 'error')
      process.exit(1)
    } else if (output.errors) {
      const warnings = {};
      output.errors.forEach((warning) => {
        const filename = warning.replace(filenamePattern, '$1');
        if (!warnings[filename]) {
          warnings[filename] = 1;
        } else {
          warnings[filename]++;
        }
      });
      this.log(`warnings per file: ${JSON.stringify(warnings, null, 2)}`);
    }
    const trimmed = {}
    Object.keys(output.contracts).forEach((key) => {
      trimmed[key] = {
        interface: output.contracts[key].interface,
        bytecode: output.contracts[key].bytecode,
      }
    })
    this.linkLibraries(trimmed);
    return this.writeContractsToFile(trimmed, dst)
  }

  linkLibraries(contracts, additionalLinks) {
    // update internal library listing with given links
    Object.assign(this.config.librariesAddresses, additionalLinks);
    // build mapping with libraries to link
    const toLink = {};
    Object.keys(this.config.librariesAddresses)
      // keep only truthy addresses
      .filter(key => this.config.librariesAddresses[key])
      // build object with links
      .forEach((key) => { toLink[key] = this.config.librariesAddresses[key]; });
    Object.keys(contracts).map((contract) => {
      contracts[contract].bytecode = linker.linkBytecode(
        contracts[contract].bytecode,
        toLink,
      )
    });
    for (let lib of Object.keys(toLink)) {
      contracts[lib].deployedAt = toLink[lib];
    }
  }

  /**
   * ensure, that compiled contracts are at given folder or at default folder and that compiled
   * contract code is up to date with latest .sol file modifications
   *
   * @param      {string[]}       additionalPaths  list of folder to check for .sol files
   * @param      {string}         dst              (optional) target folder, it doesn't need to
   *                                               exist, it will be created, uses constructor
   *                                               config property 'destinationPath' by default
   * @return     {Promise<void>}  resolved when done
   */
  async ensureCompiled(additionalPaths = [], dst) {
    let destinationPath = typeof dst === 'string' ? dst : this.config.destinationPath
    const ofile = path.resolve(destinationPath, compiledFile)
    const compiled = fs.existsSync(ofile)
    if (!(this.config.compileContracts || !compiled)) return

    // backup original runtime path to recover it
    const originalRuntimePath = process.cwd();

    // switch process dir to the current directory to handle correct node_module paths, when the
    // smart-contracts-core project was linked, too
    process.chdir(path.resolve(__dirname))

    const core_src = [solPath,
                      findup('node_modules')+'/ens/contracts',
                     ].map(modulePath => path.resolve(__dirname, modulePath))

    additionalPaths = Array.isArray(additionalPaths) ? additionalPaths : [additionalPaths]

    // navigate to the original runtime folder to prevent side effects
    process.chdir(path.resolve(originalRuntimePath))

    // having additional paths later allows you to overwrite core contracts if needed
    let src_dirs = core_src.concat(additionalPaths)
    // add files or directory content
    const src_files = src_dirs.map((d) =>
      fs.statSync(d).isFile() ? [path.basename(d)] : rread(d).map(f => f.replace('\\', '/'))
    );
    // if additional paths contained files instead of directories, trim filename
    src_dirs = src_dirs.map((d) => fs.statSync(d).isFile() ? path.dirname(d) : d);
    const src_tree = {}
    for(let i in src_dirs) {
      src_tree[src_dirs[i]] = src_files[i];
    }

    // if no compile exists, do one
    if(!compiled) return await this.compileContracts(src_tree, dst)

    return this.compileContracts(src_tree, dst);
  }

  /**
   * get compiled contracts, does not compile or recompile them
   *
   * @param      {string}  dst     (optional) target folder, uses constructor config property
   *                               'destinationPath' by default
   */
  getContracts(dst, raw = false) {
    let destinationPath = typeof dst === 'string' ? dst : this.config.destinationPath
    const contracts = require(path.resolve(destinationPath, compiledFile))
    if (raw) {
      return contracts
    } else {
      const shortenedContracts = {}
      Object.keys(contracts).forEach((key) => {
        const contractKey = (key.indexOf(':') !== -1) ? key.split(':')[1] : key
        shortenedContracts[contractKey] = contracts[key]
      })
      return shortenedContracts
    }
  }

  /**
   * write given contracts to .js and .json file
   *
   * @param      {any}           contracts  object with keys for contract defintions and values as
   *                                        abi array
   * @param      {string}        dst        (optional) target folder, uses constructor config
   *                                        property 'destinationPath' by default
   * @return     {Promise<any>}  object with fn (.js content) and .jsfn (.json content)
   */
  async writeContractsToFile(contracts, dst) {
    let destinationPath = typeof dst === 'string' ? dst : this.config.destinationPath;

    // copy the original contracts instances to delete unwanted bytecode
    const uiContracts = JSON.parse(JSON.stringify(contracts));

    // remove bytecode from frontend file
    Object.keys(uiContracts).forEach((key) => {
      delete uiContracts[key].deployedAt;
      if (this.config.uiAllowedByteCodes.indexOf(key) === -1) {
        delete uiContracts[key].bytecode
      }
    })

    // write contracts file into an seperated javascript file to be able to include it
    // into a systemjs build
    const jscontent = `(function (root, factory) {
        if (typeof define === 'function' && define.amd) {
            define([], factory);
        } else if (typeof module === 'object' && module.exports) {
            module.exports = factory();
        } else {
          root.returnExports = factory();
        }
      }(typeof self !== 'undefined' ? self : this, function () {
        return ${JSON.stringify(uiContracts)};
      }));`

    // if an destination path was provided, save them to the correct location
    if (destinationPath) {
      const fn = path.resolve(destinationPath, compiledFile);
      const jsfn = path.resolve(destinationPath, compiledJSFile);

      // create destination folder if not exists
      if (!fs.existsSync(destinationPath)) {
        fs.mkdirSync(destinationPath)
      }

      // save the files
      await Promise.all([
        promisify(fs.writeFile)(fn, JSON.stringify(contracts)),
        promisify(fs.writeFile)(jsfn, jscontent)
      ]);
    }

    return { fn: JSON.stringify(contracts), jsfn: jscontent }
  }

  getLibrariesToRedeploy() {
    const toDeploys = Object.keys(this.config.librariesAddresses)
      .filter(key => !this.config.librariesAddresses[key]);
    const nested = toDeploys.map(entry => Object.keys(this.config.libraryDependencies)
      .filter(key => this.config.libraryDependencies[key].includes(entry)));
    const toCheck = [...(new Set([].concat.apply([], nested)))];
    while (toCheck.length) {
      let entry = toCheck.shift();
      if (!toDeploys.includes(entry)) {
        toDeploys.push(entry);
        const dependants = Object.keys(this.config.libraryDependencies)
          .filter(key => this.config.libraryDependencies[key].includes(entry));
        toCheck.push.apply(toCheck, dependants);
      }
    }
    console.log(JSON.stringify(toDeploys, null, 2));
    return toDeploys;
  }
}

module.exports = Solc
