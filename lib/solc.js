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
  'KeyHolderLibrary',
  'VerificationHolder',
];

// dependencies between libraries
const libraryDependencies = {
  'verifications/VerificationHolderLibrary.sol:VerificationHolderLibrary':
    ['verifications/KeyHolderLibrary.sol:KeyHolderLibrary'],
  'BaseContractZeroLibrary.sol:BaseContractZeroLibrary':
    ['DSRolesPerContractLibrary.sol:DSRolesPerContractLibrary'],
  'DataContractLibrary.sol:DataContractLibrary':
    ['DSRolesPerContractLibrary.sol:DSRolesPerContractLibrary'],
};

// list of known and deployed smart contract libraries
// setting a value to a falsy value will depeloy it and its dependants
const librariesAddresses = {
  core: {
    'AbstractENS.sol:AbstractENS':
      '0xc913ac6522344187bc9C88C9f9302b005500FfF9',
    'verifications/KeyHolderLibrary.sol:KeyHolderLibrary':
      '0x12A05f0570e267e424DdF8AeA36C65562404892e',
    'verifications/VerificationHolderLibrary.sol:VerificationHolderLibrary':
      '0xF04e18492F98AA472070E66eaAA1D17EDeeF0726',
    'verifications/VerificationsRegistryLibrary.sol:VerificationsRegistryLibrary':
      '0x3d722d4AE00Ef88C5C4c51fC19C3B257e6d3D11E',
    'DSRolesPerContractLibrary.sol:DSRolesPerContractLibrary':
      '0x6a7631d3C7A7E89eA0Cfcc13D783D629102D14a1',
    'BaseContractZeroLibrary.sol:BaseContractZeroLibrary':
      '0x080B98aFc055C1c9d9672dd5A89b93Ef9173792b',
    'DataContractLibrary.sol:DataContractLibrary':
      '0xA52304742c86bAB72Ae070fAb0580A43731781f3',
    'DigitalTwinLibrary.sol:DigitalTwinLibrary':
      '0x21c89be4C8990413B1C225aAc91BFb7a74f33cC4',
  },
  testcore: {
    'AbstractENS.sol:AbstractENS':
      '0x937bbC1d3874961CA38726E9cD07317ba81eD2e1',
    'verifications/KeyHolderLibrary.sol:KeyHolderLibrary':
      '0x498A9beDAf23401d888b4f52fD379bBA144D2370',
    'verifications/VerificationHolderLibrary.sol:VerificationHolderLibrary':
      '0x30aD628d39F55E66aE42F7e48c741D6567AA8F55',
    'verifications/VerificationsRegistryLibrary.sol:VerificationsRegistryLibrary':
      '0xDB93AaB864031340E3D98f6Cd937FC2a51Be1998',
    'DSRolesPerContractLibrary.sol:DSRolesPerContractLibrary':
      '0x8e313491891f2d2218DECac8cE4eAF79Be368a13',
    'BaseContractZeroLibrary.sol:BaseContractZeroLibrary':
      '0x9efAFEe1c35f44639E68b56084B42017A7e6E81F',
    'DataContractLibrary.sol:DataContractLibrary':
      '0x90fF98a57176169e555B66f7e05ff5dEab9a1992',
    'DigitalTwinLibrary.sol:DigitalTwinLibrary':
      '0x21c89be4C8990413B1C225aAc91BFb7a74f33cC4',
  },
  local: {
    'AbstractENS.sol:AbstractENS':
      '0x9f8063ac44D23C99E943eA3DE3E1bb6Ab7678df0',
    'verifications/KeyHolderLibrary.sol:KeyHolderLibrary':
      '',
    'verifications/VerificationHolderLibrary.sol:VerificationHolderLibrary':
      '',
    'verifications/VerificationsRegistryLibrary.sol:VerificationsRegistryLibrary':
      '',
    'DSRolesPerContractLibrary.sol:DSRolesPerContractLibrary':
      '',
    'BaseContractZeroLibrary.sol:BaseContractZeroLibrary':
      '',
    'DataContractLibrary.sol:DataContractLibrary':
      '',
    'DigitalTwinLibrary.sol:DigitalTwinLibrary':
      '',
  },
};

class Solc {
  /**
   * creates new Solc instance
   *
   * @param      {any}  options  supports properties: compileContracts, destinationPath
   */
  constructor(options) {
    const chain = this._getEnvironment();
    this.log = options.log;
    this.config = Object.assign({}, options.config);
    this.config.uiAllowedByteCodes = uiAllowedByteCodes.concat(options.uiAllowedByteCodes || []);
    this.config.libraryDependencies =
      Object.assign({}, libraryDependencies, options.libraryDependencies);
    this.config.librariesAddresses =
      Object.assign({}, librariesAddresses[chain], options.librariesAddresses);

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
          solFiles[f] = fs.readFileSync(path.resolve(dir, f), 'utf8');
        }
      }
    }

    for (let f in solFiles) {
      solFiles[f] = {
        content: solFiles[f]
      }
    }

    const output = await new Promise((res, rej) => {
      // getting the development snapshot
      solc.loadRemoteVersion('v0.4.26+commit.4563c3fc', function (err, solcSnapshot) {
        if (err) {
          rej(err);
        } else {
          const compiled = solcSnapshot.compile(JSON.stringify({
            language: 'Solidity',
            sources: solFiles,
            settings: {
              optimizer: {
                enabled: true,
              },
              outputSelection: {
                '*': {
                  '*': [ 'abi', 'evm.bytecode.object' ],
                  '': [ 'ast' ]
                }
              }
            }
          }));
          res(JSON.parse(compiled))
        }
      })
    })

    // drop warnings
    const errors = output.errors ? output.errors.filter(error => error.severity === 'error') : null;

    if (errors && errors.length) {
      this.log('Contract compile error: \n' + JSON.stringify(errors, null, 2), 'error')
      process.exit(1)
    } else if (output.errors) {
      const warnings = {};
      output.errors.forEach((warning) => {
        if(warning.sourceLocation && warning.sourceLocation.file) {
          const filename = warning.sourceLocation.file;
          if (!warnings[filename]) {
            warnings[filename] = 1;
          } else {
            warnings[filename]++;
          }
        }
      });
      this.log(`warnings per file: ${JSON.stringify(warnings, null, 2)}`);
    }
    const trimmed = {}
    Object.keys(output.contracts).forEach((fileName) => {

      Object.keys(output.contracts[fileName]).forEach((contractName) => {
        trimmed[contractName] = {
          interface: JSON.stringify(output.contracts[fileName][contractName].abi),
          bytecode: output.contracts[fileName][contractName].evm.bytecode.object,
        }
      });

    })
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

    const ensRegex = new RegExp(librariesAddresses.testcore['AbstractENS.sol:AbstractENS'].replace('0x', ''), 'i');
    const chain = this._getEnvironment();
    for (const contract of Object.keys(contracts)) {
      contracts[contract].bytecode = linker
        .linkBytecode(contracts[contract].bytecode, toLink)
        .replace(ensRegex, librariesAddresses[chain]['AbstractENS.sol:AbstractENS']);

    }

    for (let lib of Object.keys(toLink)) {
      const libContract = lib.split(':');
      contracts[libContract[1]].deployedAt = toLink[lib];
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

    const core_src = [ path.resolve(__dirname, solPath) ]

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
    this.linkLibraries(contracts)
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
    const cleanUiContracts = JSON.parse(JSON.stringify(contracts));
    const uiContracts = { };

    // remove bytecode from frontend file
    Object.keys(cleanUiContracts).forEach((key) => {
      delete cleanUiContracts[key].deployedAt;
      if (this.config.uiAllowedByteCodes.indexOf(key) === -1) {
        delete cleanUiContracts[key].bytecode
      }
    });

    // map the contracts value object correctly
    Object.keys(cleanUiContracts).forEach((key) => {
      const contractKey = (key.indexOf(':') !== -1) ? key.split(':')[1] : key;
      uiContracts[contractKey] = cleanUiContracts[key];
    });

    // write contracts file into an seperated javascript file to be able to include it
    // into a systemjs build
    const jscontent = `
    const contracts = ${JSON.stringify(uiContracts)};
    const libraries = ${JSON.stringify(librariesAddresses)};
    var linkBytecode = function (bytecode, libraries) {
      // NOTE: for backwards compatibility support old compiler which didn't use file names
      var librariesComplete = {};
      for (var libraryName in libraries) {
        if (typeof libraries[libraryName] === 'object') {
          // API compatible with the standard JSON i/o
          for (var lib in libraries[libraryName]) {
            librariesComplete[lib] = libraries[libraryName][lib];
            librariesComplete[libraryName + ':' + lib] = libraries[libraryName][lib];
          }
        } else {
          // backwards compatible API for early solc-js versions
          var parsed = libraryName.match(/^([^:]+):(.+)$/);
          if (parsed) {
            librariesComplete[parsed[2]] = libraries[libraryName];
          }
          librariesComplete[libraryName] = libraries[libraryName];
        }
      }

      for (libraryName in librariesComplete) {
        var hexAddress = librariesComplete[libraryName];
        if (hexAddress.slice(0, 2) !== '0x' || hexAddress.length > 42) {
          throw new Error('Invalid address specified for ' + libraryName);
        }
        // remove 0x prefix
        hexAddress = hexAddress.slice(2);
        hexAddress = Array(40 - hexAddress.length + 1).join('0') + hexAddress;

        // Support old (library name) and new (hash of library name)
        // placeholders.
        var replace = function (name) {
          // truncate to 37 characters
          var truncatedName = name.slice(0, 36);
          var libLabel = '__' + truncatedName + Array(37 - truncatedName.length).join('_') + '__';
          while (bytecode.indexOf(libLabel) >= 0) {
            bytecode = bytecode.replace(libLabel, hexAddress);
          }
        };

        replace(libraryName);
      }

      return bytecode;
    };
    var linkLibraries = function(contracts, chain) {
      // build mapping with libraries to link
      const toLink = {};
      Object.keys(libraries[chain])
        // keep only truthy addresses
        .filter(key => libraries[key])
        // build object with links
        .forEach((key) => { toLink[key] = libraries[key]; });
      Object.keys(contracts).map((contract) => {
        if(contracts[contract].bytecode){
          contracts[contract].bytecode = linkBytecode(
            contracts[contract].bytecode,
            toLink,
          )
        }
      });
      for (let lib of Object.keys(toLink)) {
        const libContract = lib.split(':');
        contracts[libContract[1]].deployedAt = toLink[lib];
      }
    }

    var getGlobal = function () {
      if (typeof self !== 'undefined') { return self; }
      if (typeof window !== 'undefined') { return window; }
      if (typeof global !== 'undefined') { return global; }
      throw new Error('unable to locate global object');
    };

    var _getEnvironment = function() {
      let chain = 'testcore';
      const globals = getGlobal();
      if(!globals.process) {
          globals.process = {}
      }
      if(globals.process && globals.process.env && (globals.process.env.NODE_ENV === 'testcore' || globals.process.env.NODE_ENV === 'core')) {
        chain = globals.env.NODE_ENV;
      }

      if(globals.process && globals.process.env && (globals.process.env.EVAN_CHAIN === 'testcore' || globals.process.env.EVAN_CHAIN === 'core')) {
        chain = globals.process.env.EVAN_CHAIN;
      }

      return chain;
    }
    module.exports = linkLibraries(contracts, _getEnvironment());`

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
    return toDeploys;
  }

  /**
   * retrieves chain name from environment, defaults to 'testcore'
   *
   * @return     {string}  name of current chain
   */
  _getEnvironment() {
    let chain = 'testcore';

    if(process.env.NODE_ENV === 'testcore' || process.env.NODE_ENV === 'core') {
      chain = process.env.NODE_ENV;
    }

    if(process.env.EVAN_CHAIN === 'testcore' || process.env.EVAN_CHAIN === 'core') {
      chain = process.env.EVAN_CHAIN;
    }

    return chain;
  }
}

module.exports = Solc
