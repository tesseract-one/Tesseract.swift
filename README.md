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

#### For Ethereum Network

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

print("Do we have wallet with KeychainAPI?:", Tesseract.Ethereum.isKeychainInstalled)

```

Application should perform this check before using APIs.

Let's try to use Web3

```swift
import Tesseract

// HTTP RPC URL
let rpcUrl = "https://mainnet.infura.io/v3/{API-KEY}"

// Creating Web3 instance. Try to reuse existing instance of Web3.
let web3 = Tesseract.Ethereum.Web3(rpcUrl: rpcUrl)

// Sending it. Tesseract will handle signing automatically.
web3.eth.accounts() { response in
    switch response.status {
    case .success(let accounts): print("Account:", accounts[0])
    case .failure(let err): print("Error:", error)
    }
}

// With PromiseKit enabled
import PromiseKit

firstly {
    web3.eth.accounts()
}.done { accounts in
    print("Account:", accounts[0])
}.catch { err in
    print("Error:", error)
}
```

### Examples

#### New transaction

```swift
import Tesseract

// HTTP RPC URL
let rpcUrl = "https://mainnet.infura.io/v3/{API-KEY}"

// Creating Web3 instance. Try to reuse existing instance of Web3.
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
import PromiseKit

firstly {
    web3.eth.sendTransaction(transaction: tx)
}.done { hash in
    print("TX Hash:", hash.hex())
}.catch { err in
    print("Error:", error)
}
```

#### ERC20 Smart Contract

```swift
import Tesseract
import PromiseKit

// HTTP RPC URL
let rpcUrl = "https://mainnet.infura.io/v3/{API-KEY}"

// Creating Web3 instance. Try to reuse existing instance of Web3.
let web3 = Tesseract.Ethereum.Web3(rpcUrl: rpcUrl)

let contractAddress = try EthereumAddress(hex: "0x86fa049857e0209aa7d9e616f7eb3b3b78ecfdb0", eip55: true)
let contract = web3.eth.Contract(type: GenericERC20Contract.self, address: contractAddress)

// Get balance of some address
firstly {
    try contract.balanceOf(address: EthereumAddress(hex: "0x3edB3b95DDe29580FFC04b46A68a31dD46106a4a", eip55: true)).call()
}.done { outputs in
    print(outputs["_balance"] as? BigUInt)
}.catch { error in
    print(error)
}

// Send some tokens to another address
let myAddress = try EthereumAddress(hex: "0x1f04ef7263804fafb839f0d04e2b5a6a1a57dc60", eip55: true)
firstly {
    web3.eth.getTransactionCount(address: myAddress, block: .latest)
}.then { nonce in
    try contract.transfer(to: EthereumAddress(hex: "0x3edB3b95DDe29580FFC04b46A68a31dD46106a4a", eip55: true), value: 100000).send(
        nonce: nonce,
        from: myAddress,
        value: 0,
        gas: 150000,
        gasPrice: EthereumQuantity(quantity: 21.gwei)
    )
}.done { txHash in
    print(txHash)
}.catch { error in
    print(error)
}
```

#### More Examples

For more examples check [Web3.swift](https://github.com/Boilertalk/Web3.swift) library used inside.

## Author

 - [Tesseract Systems, Inc.](mailto:info@tesseract.one)
   ([@tesseract_one](https://twitter.com/tesseract_one))

## License

`Tesseract.swift` is available under the Apache 2.0 license. See [the LICENSE file](https://raw.githubusercontent.com/tesseract-one/Tesseract.swift/master/LICENSE) for more information.
