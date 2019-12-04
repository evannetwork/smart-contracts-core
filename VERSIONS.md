# smart-contracts-core

## Next Version
### Features
- add `DidRegistry` for storing DID document hashes

### Fixes

### Deprecations


## Version 2.7.0
### Features
- add support for making generic transactions via identities
- add event `ContractCreated` to identity
- add ability to receive funds to identities

### Fixes
- fix `build-contract` helper script


## Version 2.6.2
### Fixes
- align license of tool script with rest of project


## Version 2.6.1
### Fixes
- fix container factory permissions


## Version 2.6.0
### Features
- performance/cost optimizations for `ContainerDataContractFactory`
  + set permissions with fewer transactions
  + remove default contract state flow of `DataContract` instances
  + add identity creation
- (smaller) performance/cost optimization for `BaseContractFactory`
  + use pregenerated hashes for permissions


## Version 2.5.0
### Features
- update versions of dependencies


## Version 2.4.3
### Fixes
- reduce data returned from contract compilation to restore pre-update behavior
- improve ens contract path resolval logic


## Version 2.4.2
### Fixes
- fix `"web3": "1.0.0-beta.55"` transaction resolval behavior for `build-contracts`


## Version 2.4.1
### Fixes
- update for `web3` version `1.0.0-beta.55` support (for `build-contracts` script)


## Version 2.4.0
### Features
- add delegation support to ``KeyHolder``
  + delegated calls require a signed hash, that is built from transaction input, identity address and its transaction nonce
  + delegated calls can be executed by anyone, but require the signer to have correct keys


## Version 2.3.1
### Fixes
- update ``VerificationHolderLibrary`` to allow only subject to approve
- remove obsolite ``build-docu`` scripts
- add scripts folder to npm publishing


## Version 2.3.0
### Features
- update ``IdentityHolder`` and ``VerificationsRegistryLibrary`` to work with with ``bytes32`` as ``links`` (pseudonyms or addresses) for full 32B pseudonym range support
- update ``IdentityHolder`` with ``migrateIdentity`` function, that allows to migrate identities into it, as long, as identity is not claimed yet

### Fixes
- update ``IdentityHolder``
  - properly returns created identity from ``createIdentity``
  - getter functions uses ``view`` modifier
- update gas price in contract deploy script to 200GWei


## Version 2.2.0
### Features
- add `requestOwnerTicket` function to `TicketVendorInterface`

### Fixes
- build correct `compiled.js` format (remove colons)


## Version 2.1.1
### Fixes
- remove admin contracts from smart agent config


## Version 2.1.0
### Features
- add self governed implementation of multisig wallet
- add index contracts and container factory for digital identities

### Fixes
- add getter for former `BaseContract` public properties

### Deprecations
- removed `dbcp.json` and moved it to [ui-core/dapps/smartcontracts](https://github.com/evannetwork/ui-core/tree/master/dapps/smartcontracts))


## Version 2.0.0
### Features
- already deployed libraries can be given as property `librariesAddresses` to constructor
- bytecodes to keep in reduced compiled file can be given as propety `allowedByteCodes` to constructor
- dependencies between libraries can be given as property `libraryDependencies` to constructor
- setting property `compileContracts` to `true` now compiles contracts, even if source files have not changed since last compile time
- update `build-contracts` to deploy missing libraries
- add `deployedAt` for libraries in compiled contracts
- add flag `disableSubVerifications` to verifications
- wallet only keeps hash of original input and deletes data after executing it

### Deprecations
- `DSRolesPerContract` uses own lib for logic
- `BaseContractZero` (temporary name) uses own lib for logic but breaks compatibility with regular `BaseContract` inheritance
- `DataContract` uses own lib for logic, inherits from `BaseContractZero` instead of regular `BaseContract`
- `EnsReader` contract `getAddr` is now public
- replace dependency of `DataContractIndex` with `DataContractIndexInterface` in `BusinessCenterInterface`
- `KeyHolder` constructor now needs an address argument for settings its owner


## 1.5.2 Version
### Fixes
- Fix linking of libraries


## 1.5.1 Version
### Fixes
- Fix linking of libraries


## Version 1.5.0
### Features
- add contracts for creating verifications for contracts
- add function for registering other users identities, that can be used by registry owner, can only be set this way if account to register doesn't already have an identity
- add missing dbcpVersion to dbcp files
- add licenses to dbcp files

### Fixes
- remove `OriginIdentity`, as `VerificationHolder` is used for identities


## Version 1.4.0
### Features
- add `PayableRegistrar`, that allows to by domain names with EVEs for limited time frames
- add `TimedENS`, that allows to register domains for limited time frames


## Version 1.3.0
### Features
- add description to verifications
- add `addVerificationWithMetadata` function to verifications for setting verification and metadata at the same time
- add creation block data to verification information
- verifications are not overwritten anymore, but a new verification is created per set call
- add `Congress.sol` for holding votes on-chain

### Fixes
### Deprecations


## Version 1.2.0
### Features
- add ERC725/735 compliant Verifications and Identity contracts
- include bytecode within compiled.js files for `verifications/OriginIdentity.sol:OriginIdentity`
- add `TicketVendorInterface`

### Deprecations
- use solc 0.4.24 as compiler version
- contracts have been updated accordingly to match solc 0.4.24
- make compiler versions upward compatible (`^solc 0.4.24`)


## Version 1.1.3
### Features
- add permissions to `TestDataContractFactory` for additional test for user management

### Fixes
- fix `setUserRole` issue in `DSRolesPerContract`, that could produce invalid user indices when removing accounts from roles


## Version 1.1.2
### Fixes
- fix destinationPath handling for cases when output file doesn't exist
- fix `removeContractMember`
- add `dst` argument to contract compile functions
- add provider (owner of new `BaseContract`) as a consumer to internal mappings, that reflect this state


## Version 1.1.1
### Fixes
- use `keccak256` instead of `sha3` for hashing
- add `dst` argument to `lib/solc.js` functions to bypass config for destination path
- add support for removing contract members the same way as inviting them


## Version 1.1.0
### Fixes
- update hasing to `keccak256`
- add `registerFactory(address factoryId)` to `BusinessCenterInterface`
- add matching auth checks


## Version 1.0.3
### Features
- add configurable output path
- add modified times check for files from additional paths
- add interface `MailBoxInterface` for interacting with global mailbox contract
- add test contracts `TestContract` and `TestContractFactory` for automatic testing
- add factory for `MultiSigWallet` contracts
- change call and answer storage formate in `ServiceContract.sol` to structs
- add more properties to result of `getCalls` and `getAnswers` in `ServiceContract.sol`
- add `registerFactory(address factoryId)` to `BusinessCenterInterface`

### Fixes
- remove `MultiSigWallet` dependency by copying `.sol` file into contracts folder, to prevent `npm install` issues, when used as a subdependency
- add cloning for config option in Solc module to avoid side effects

### Deprecations
- deprecated rarely used (in edge-server) bin/compile.js


## Version 0.9.0
- initial version and release candidate for 1.0.0
