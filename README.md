[![GitHub license](https://img.shields.io/badge/license-Apache%202.0-lightgrey.svg)](https://raw.githubusercontent.com/tesseract-one/Tesseract.swift/master/LICENSE)
[![Build Status](https://travis-ci.com/tesseract-one/Tesseract.swift.svg?branch=master)](https://travis-ci.com/tesseract-one/Tesseract.swift)
[![GitHub release](https://img.shields.io/github/release/tesseract-one/Tesseract.swift.svg)](https://github.com/tesseract-one/Tesseract.swift/releases)
[![CocoaPods version](https://img.shields.io/cocoapods/v/Tesseract.svg)](https://cocoapods.org/pods/Tesseract)
![Platform iOS](https://img.shields.io/badge/platform-iOS-orange.svg)

## Tesseract DApps Platform SDK for Swift

Tesseract DApps Platform allows building of Native Swift DApps for iOS (and macOS in the nearest future).

It's emerged from one simple idea - DApps should not store Private Keys inside.

With this vision we created Mobile-first platform, which allows developers to write Native DApps without keychain inside.

For this purpose we have open protocol for Wallets called [Open Wallet](https://github.com/tesseract-one/OpenWalletProtocol).

This SDK can interact with any Wallet which implemented [Open Wallet](https://github.com/tesseract-one/OpenWalletProtocol) protocol.

We created our own [Tesseract Wallet](https://itunes.apple.com/us/app/tesseract-wallet/id1459505103) as reference wallet implementation. It can be used with this SDK for DApp development. Install it on your device to check provided examples.

## Getting started

### Installation

#### SDK Structure

This SDK has modular structure. All modules can be installed with CocoaPods.

Right now SDK has this modules:

* Tesseract.OpenWallet - reference OpenWallet client implementation. Main part of SDK
* Tesseract.Ethereum - metapackage, which will install all Ethereum modules
  * Tesseract.Ethereum.Web3 - Web3 implementation for Swift with OpenWallet support
* Tesseract.Ethereum.PromiseKit - metapackage, which will install all Ethereum modules with PromiseKit support
  * Tesseract.Ethereum.Web3.PromiseKit - PromiseKit extensions for Web3.

#### For Ethereum Network (with metapackage)

##### With Metapackage

Add the following to your [Podfile](http://guides.cocoapods.org/using/the-podfile.html):

```rb
pod 'Tesseract/Ethereum'

# Uncomment this line if you want to enable PromiseKit extensions
# pod 'Tesseract/Ethereum.PromiseKit'
```

Then run `pod install`.

##### Web3 only

Add the following to your [Podfile](http://guides.cocoapods.org/using/the-podfile.html):

```rb
pod 'Tesseract/Ethereum.Web3'

# Uncomment this line if you want to enable PromiseKit extensions
# pod 'Tesseract/Ethereum.Web3.PromiseKit'
```

Then run `pod install`.

### Getting Started

Let's check that we have Wallet with [Open Wallet](https://github.com/tesseract-one/OpenWalletProtocol) support installed and it supports Ethereum Keychain APIS.

```swift
import Tesseract

print("Do we have wallet?:", Tesseract.OpenWallet.walletHasAPI(keychain: .Ethereum))

```

Application should perform this check before using APIs.

### Supported methods

For the list of supported methods and API reference check [Boilertalk/Web3.swift](https://github.com/Boilertalk/Web3.swift) repository.

### Examples

#### [OpenWallet.swift](https://github.com/tesseract-one/OpenWallet.swift) (Client)

##### New transaction

```swift
import Tesseract

// HTTP RPC URL
let rpcUrl = "https://mainnet.infura.io/v3/{API-KEY}"

// Initializing OpenWallet with Ethereum. Creating Web3 instance
// Store your OpenWallet instance somewhere(AppDelegate, Context). It should be reused.
// If you need only Web3, you can store it only(it will store OpenWallet inside itself).
let web3 = Tesseract.Ethereum.Web3(rpcUrl: rpcUrl)

// Creating Transaction
let tx = EthereumTransaction(
    from: try! EthereumAddress(hex: "0x...", eip55: false),
    to: try! EthereumAddress(hex: "0x...", eip55: false),
    value: 1.eth
)

// Sending it. Tesseract will handle signing automatically.
web3.eth.sendTransaction(transaction: tx) { response in
    switch response.status {
    case .success(let hash): print("TX Hash:", hash.hex())
    case .failure(let err): print("Error:", error)
    }
}

// With PromiseKit enabled

```

#### [Wallet.swift](https://github.com/tesseract-one/Wallet.swift) (Wallet)

##### New transaction

```swift
import Wallet
import EthereumWeb3

// Path to sqlite database with wallets
let dbPath = "path/to/database.sqlite"

// Wallet Storage
let storage = try! DatabaseWalletStorage(path: dbPath)

// Applying migrations
try! storage.bootstrap()

// Creating manager with Ethereum network support
let manager = try! Manager(networks: [EthereumNetwork()], storage: storage)

// Restoring wallet data from mnemonic
let walletData = try! manager.restoreWalletData(mnemonic: "aba caba ...", password: "12345678")

// Creating wallet from data
let wallet = try! manager.create(from: walletData)

// Unlocking wallet
try! wallet.unlock(password: "12345678")

// Adding first account 
let account = wallet.addAccount()

// HTTP RPC URL
let rpcUrl = "https://mainnet.infura.io/v3/{API-KEY}"

// Creating Web3 for this Wallet
let web3 = wallet.ethereum.web3(rpcUrl: rpcUrl)

// Creating Transaction
let tx = EthereumTransaction(
    from: try! account.eth_address().web3,
    to: try! EthereumAddress(hex: "0x...", eip55: false),
    value: 1.eth
)

// Wallet will sign this transaction automatically (with 'from' account)
web3.eth.sendTransaction(transaction: tx) { response in
    switch response.status {
    case .success(let hash): print("TX Hash:", hash.hex())
    case .failure(let err): print("Error:", error)
    }
}
```

## Author

 - [Tesseract Systems, Inc.](mailto:info@tesseract.one)
   ([@tesseract_one](https://twitter.com/tesseract_one))

## License

`EthereumWeb3.swift` is available under the Apache 2.0 license. See [the LICENSE file](https://raw.githubusercontent.com/tesseract-one/EthereumWeb3.swift/master/LICENSE) for more information.
