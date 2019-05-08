# Tesseract dApps Platform SDK for Swift
[![GitHub license](https://img.shields.io/badge/license-Apache%202.0-lightgrey.svg)](https://raw.githubusercontent.com/tesseract-one/Tesseract.swift/master/LICENSE)
[![Build Status](https://travis-ci.com/tesseract-one/Tesseract.swift.svg?branch=master)](https://travis-ci.com/tesseract-one/Tesseract.swift)
[![GitHub release](https://img.shields.io/github/release/tesseract-one/Tesseract.swift.svg)](https://github.com/tesseract-one/Tesseract.swift/releases)
[![CocoaPods version](https://img.shields.io/cocoapods/v/Tesseract.svg)](https://cocoapods.org/pods/Tesseract)
![Platform iOS](https://img.shields.io/badge/platform-iOS-orange.svg)

## Getting started

To use this library compatible wallet should be installed on the device.

We released our own [Tesseract Wallet](https://itunes.apple.com/us/app/tesseract-wallet/id1459505103) as reference wallet implementation.
Install it on your device to check provided examples.

### Ethereum

#### Installation

Add the following to your [Podfile](http://guides.cocoapods.org/using/the-podfile.html):

```rb
pod 'TesseractSDK/Ethereum'
```

Then run `pod install`.

#### Hello Tesseract, hello Web3.

Let's try to get Ethereum account balance.

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
pod 'TesseractSDK/Ethereum.PromiseKit'

```

Then run `pod install`.

##### Now you can Web3 like this

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
let tx = Ethereum.Transaction(
    from: account, // Account from previous examples
    to: try! Ethereum.Address(hex: "0x...", eip55: false),
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
let contractAddress = try! Ethereum.Address(hex: "0x86Fa049857E0209aa7D9e616F7eb3b3B78ECfdb0", eip55: true)
// ERC20 contract object
let contract = web3.eth.Contract(type: GenericERC20Contract.self, address: contractAddress)
```

##### Get ERC20 balance

```swift
contract.balanceOf(address: account) // Account from previous steps
    .call() // Performing Ethereum Call
    .done { outputs in
        print("Balance:", outputs["_balance"] as! BigUInt)
    }.catch { error in
        print("Error:", error)
    }
```

##### Send ERC20 tokens

```swift
// Our recipient
let recipient = try! Ethereum.Address(hex: "0x....", eip55: true)

contract
    .transfer(to: recipient, value: 100000) // Creating SC invocaion
    .send(from: account) // Sending it from our account
    .done { hash in
        print("TX Hash:", hash.hex())
    }.catch { err in
        print("Error:", err)
    }
```

#### Custom Smart Contract

Web3 can parse you JSON smart contract ABI.

You can use methods of Smart Contract by subcripting them by name from the Contract object.

##### Create Smart Contract instance

```swift
// EOS ERC20 token
let contractAddress = try! Ethereum.Address(hex: "0x86Fa049857E0209aa7D9e616F7eb3b3B78ECfdb0", eip55: true)
// JSON ABI. Can be loaded from json file
let contractJsonABI = "<your contract ABI as a JSON string>".data(using: .utf8)!
// You can optionally pass an abiKey param if the actual abi is nested and not the top level element of the json
let contract = try web3.eth.Contract(json: contractJsonABI, abiKey: nil, address: contractAddress)
```

##### Get ERC20 balance

```swift
contract["balanceOf"]!(account) // Account from previous steps
    .call()
    .done { outputs in
        print("Balance:", outputs["_balance"] as! BigUInt)
    }.catch { error in
        print("Error:", error)
    }
```

##### Send ERC20 tokens

```swift
// Our recipient
let recipient = try! Ethereum.Address(hex: "0x....", eip55: true)

// Creating ERC20 call object
let invocation = contract["transfer"]!(recipient, BigUInt(100000))

invocation
    .send(from: account) // Sending it from our account
    .done { hash in
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

* [Tesseract.OpenWallet](https://github.com/tesseract-one/OpenWallet.swift) - reference [OpenWallet](https://github.com/tesseract-one/OpenWalletProtocol) client implementation. Main part of SDK
* __Tesseract.Ethereum__ - metapackage, which will install all Ethereum modules
  * [Tesseract.Ethereum.Web3](https://github.com/tesseract-one/EthereumWeb3.swift) - Web3 implementation for Swift with OpenWallet support
* __Tesseract.Ethereum.PromiseKit__ - metapackage, which will install all Ethereum modules with PromiseKit support
  * [Tesseract.Ethereum.Web3.PromiseKit](https://github.com/tesseract-one/EthereumWeb3.swift) - PromiseKit extensions for Web3.

### Modules installation

Modules can be installed one-by-one.

As example, if you want to install Web3 only add the following to your [Podfile](http://guides.cocoapods.org/using/the-podfile.html):

```rb
pod 'TesseractSDK/Ethereum.Web3'

# Uncomment this line if you want to enable Web3 PromiseKit extensions
# pod 'TesseractSDK/Ethereum.Web3.PromiseKit'
```

Then run `pod install`.

## Ideology behind

[Tesseract dApps Platform](https://tesseract.one) emerged from one simple vision - dApps should not store Private Keys inside.

With this vision we created Mobile-first platform. It allows app developers to write Native dApps and leave all key storage security tasks to Wallet developers.

We started with open protocol, which describes Wallet <-> dApp communication. It's called [Open Wallet](https://github.com/tesseract-one/OpenWalletProtocol).

This SDK can interact with any Wallet which implemented this protocol. Ask your preferred Wallet to implement it :)

## Author

 - [Tesseract Systems, Inc.](mailto:info@tesseract.one)
   ([@tesseract_one](https://twitter.com/tesseract_one))

## License

`Tesseract.swift` is available under the Apache 2.0 license. See [the LICENSE file](https://raw.githubusercontent.com/tesseract-one/Tesseract.swift/master/LICENSE) for more information.
