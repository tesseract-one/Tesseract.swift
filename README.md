[![GitHub license](https://img.shields.io/badge/license-Apache%202.0-lightgrey.svg)](https://raw.githubusercontent.com/tesseract-one/Tesseract.swift/master/LICENSE)
[![Build Status](https://travis-ci.com/tesseract-one/Tesseract.swift.svg?branch=master)](https://travis-ci.com/tesseract-one/Tesseract.swift)
[![GitHub release](https://img.shields.io/github/release/tesseract-one/Tesseract.swift.svg)](https://github.com/tesseract-one/Tesseract.swift/releases)
[![CocoaPods version](https://img.shields.io/cocoapods/v/Tesseract.svg)](https://cocoapods.org/pods/Tesseract)
![Platform iOS](https://img.shields.io/badge/platform-iOS-orange.svg)

## Tesseract DApps Platform SDK for Swift

## Getting started

### Ethereum

To use this library compatible wallet should be installed on the device.

We released our own [Tesseract Wallet](https://itunes.apple.com/us/app/tesseract-wallet/id1459505103) as reference wallet implementation. Install it on your device to check provided examples.

#### Installation

Add the following to your [Podfile](http://guides.cocoapods.org/using/the-podfile.html):

```rb
pod 'Tesseract/Ethereum'
```

Then run `pod install`.

#### Get account balance

Let's try to get account balance.

```swift
import Tesseract

// Check that we have wallet installed. You should handle this situation in your app.
guard Tesseract.Ethereum.isKeychainInstalled else {
    fatalError("Wallet is not installed!")
}

// Our HTTP RPC URL. Can be Infura
let rpcUrl = "https://mainnet.infura.io/v3/{API-KEY}"

// Creating Web3 instance. Try to reuse existing instance of Web3 in your app.
let web3 = Tesseract.Ethereum.Web3(rpcUrl: rpcUrl)

// Asking wallet for the Account
web3.eth.accounts() { response in
    // Check that we have response
    guard let accounts = response.result else {
        print("Error:", response.error!)
        return
    }
    // Asking network for balance
    web3.eth.getBalance(address: accounts[0], block: .latest) { response in
        switch response.status {
        case .success(let balance): print("Balance:", balance)
        case .failure(let err): print("Error:", err)
        }
    }
}
```

#### With PromiseKit

##### Install PromiseKit Extensions

Add the following to your [Podfile](http://guides.cocoapods.org/using/the-podfile.html):

```rb
pod 'Tesseract/Ethereum.PromiseKit'

```

Then run `pod install`.

#### Use them

```swift
import PromiseKit

// Asking wallet for Account
web3.eth.accounts()
    .then { accounts in
        // Obtaining balance
        web3.eth.getBalance(address: accounts[0], block: .latest)
    }.done { balance in
        print("Balance:", balance)
    }.catch { err in
        print("Error:", err)
    }
```

### Examples

#### New transaction

```swift
// Creating Transaction
let tx = EthereumTransaction(
    from: account, // Account from previous examples
    to: try! EthereumAddress(hex: "0x...", eip55: false),
    value: 1.eth
)

// Sending it. Tesseract will handle signing automatically.
web3.eth.sendTransaction(transaction: tx) { response in
    switch response.status {
    case .success(let hash): print("TX Hash:", hash.hex())
    case .failure(let err): print("Error:", err)
    }
}
```

##### PromiseKit

```swift
// Sending it. Tesseract will handle signing automatically.
web3.eth.sendTransaction(transaction: tx)
    .done { hash in
        print("TX Hash:", hash.hex())
    }.catch { err in
        print("Error:", err)
    }
```

#### ERC20 Smart Contract

##### Create Smart Contract instance

```swift
// EOS ERC20 token
let contractAddress = try! EthereumAddress(hex: "0x86Fa049857E0209aa7D9e616F7eb3b3B78ECfdb0", eip55: true)
// ERC20 contract object
let contract = web3.eth.Contract(type: GenericERC20Contract.self, address: contractAddress)
```

##### Get ERC20 balance

```swift
contract.balanceOf(address: account) // Account from previous steps
    .call()
    .done { outputs in
        print("Balance:", outputs["_balance"] as! BigUInt)
    }.catch { error in
        print("Error:", error)
    }
```

#### Send ERC20 tokens

```swift
let recepient = try! EthereumAddress(hex: "0x....", eip55: true)

// Creating ERC20 call object
let invocation = contract.transfer(to: recepient, value: 100000)

invocation
    .estimateGas(from: account) // Estimating gas needed for this call
    .then { gas in
        invocation.send(from: account, gas: gas) // Executing it
    }.done { hash in
        print("TX Hash:", hash.hex())
    }.catch { err in
        print("Error:", err)
    }
```

#### More Examples

For more examples check [Web3.swift](https://github.com/Boilertalk/Web3.swift) library used inside.

## SDK Structure

This SDK has modular structure. All modules can be installed with CocoaPods.

Right now SDK has this modules:

* Tesseract.OpenWallet - reference OpenWallet client implementation. Main part of SDK
* Tesseract.Ethereum - metapackage, which will install all Ethereum modules
  * Tesseract.Ethereum.Web3 - Web3 implementation for Swift with OpenWallet support
* Tesseract.Ethereum.PromiseKit - metapackage, which will install all Ethereum modules with PromiseKit support
  * Tesseract.Ethereum.Web3.PromiseKit - PromiseKit extensions for Web3.

### Modules installation

Modules can be installed one-by-one.

As example, if you want to install Web3 only add the following to your [Podfile](http://guides.cocoapods.org/using/the-podfile.html):

```rb
pod 'Tesseract/Ethereum.Web3'

# Uncomment this line if you want to enable Web3 PromiseKit extensions
# pod 'Tesseract/Ethereum.Web3.PromiseKit'
```

Then run `pod install`.

## Author

 - [Tesseract Systems, Inc.](mailto:info@tesseract.one)
   ([@tesseract_one](https://twitter.com/tesseract_one))

## License

`Tesseract.swift` is available under the Apache 2.0 license. See [the LICENSE file](https://raw.githubusercontent.com/tesseract-one/Tesseract.swift/master/LICENSE) for more information.
