<p align="left">
	<a href="http://tesseract.one/">
		<img alt="Tesseract" src ="./.github/logo-horiz.svg" height=128/>
	</a>
</p>

# Tesseract on iOS for dApp developers

Integration of Tesseract into your dApp allows it to request any Tesseract-compatible wallet to sign a transaction. Currently Tesseract enables native dApps to integrate with wallets through IPC, which from the user perspective is just a modal screen from the wallet.

## Getting started

Getting **Tesseract** to work in iOS dApp is different from everywhere else only by the transports set it supports.

Currently we provide IPC transport, which allows the wallets to present their screens on top of iOS applications on request and sign the transactions.

## Installation

### Add Tesseract.swift dependency

1. Add [Tesseract.swift](https://github.com/tesseract-one/Tesseract.swift) repository dependency through `File` -> `Add Package` menu in Xcode.
2. Add `TesseractClient` framework dependency to your target.

### Add supported network protocols to your target
Add list of blockchain protocols needed for you dApp in target `Info.plist` (in this example `test` and `substrate-v1` protocols)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>LSApplicationQueriesSchemes</key>
	<array>
		<string>tesseract+test</string>
		<string>tesseract+substrate-v1</string>
	</array>
</dict>
</plist>
```

## Services

Each unique Blockchain protocol represented in Tesseract as a service. Service is a class with methods, and can be obtained from Tesseract instance.

Let's take a look at the `SubstrateService` from [SubstrateService.swift](./Sources/TesseractShared/Protocols/SubstrateService.swift).:

```swift
public protocol SubstrateService: SubstrateServiceResult {
    func getAccount(
        type: SubstrateAccountType
    ) async throws -> SubstrateGetAccountResponse
    
    func signTransaction(
        type: SubstrateAccountType, path: String,
        extrinsic: Data, metadata: Data, types: Data
    ) async throws -> Data
}
```

There are two async methods in this service. One to get a public key from the wallet, another - to sign transaction.
If you prefer more functional style - there are two more methods in parent `SubstrateServiceResult` which return `Result` instead of throwing.

## Transport

For now Tesseract supports only iOS IPC transport which called `IPCTransportIOS`.

Transport should be created and provided to the `Tesseract` instance. See example bellow.

Full documentation on Transports development can be found here: [Transports How To](./TRANSPORTS.MD)

## Delegate

`Tesseract` accepts delegate object for transport selection. dApp can ask user to select one of the available transports, and returns it's id back. Or return `nil` to cancel.

Delegate is strong referenced(it stored in Rust), so be aware of memory cycles.

Here is an example implementation from [Example](./Examples/Swift/DApp/AppCore.swift):

```swift
final class TesseractTransportDelegate: TesseractDelegate {
    private weak var alerts: AlertProvider!
    
    init(alerts: AlertProvider) {
        self.alerts = alerts
    }
    
    func select(transports: Dictionary<String, Status>) async -> String? {
        assert(transports.count == 1, "How the heck do we have more than one transport here?")
        let transport = transports.first!
        switch transport.value {
        case .ready: return transport.key
        case .unavailable(let why):
            await alerts.showAlert(alert: "Transport '\(transport.key)' is not available because of the following reason: \(why)")
            return nil
        case .error(let err):
            await alerts.showAlert(alert: "Transport '\(transport.key)' is not available because the transport produced an error: \(err)")
            return nil
        }
    }
}
```

## Initialization

Here is a typical Tesseract initialization snippet (the example is taken from [Example](./Examples/Swift/DApp/AppCore.swift)):

```swift

// Create Tesseract with default transports
let tesseract = try Tesseract.default(delegate: TesseractTransportDelegate(alerts: alerts))

// Or add them manually
// let tesseract = try Tesseract(delegate: TesseractTransportDelegate(alerts: alerts))
//      .transport(IPCTransportIOS())

// Create needed services
let testService = tesseract.service(TestService.self)

// Call methods
let signed = try await testService.signTransaction(req: "Some request")
```

## Conclusion

We tried our best to present an API as easy for the dApp developer as we could and handled all the edge cases we know of inside the library. At least we improved it to the point that it satisfied us while building the [polkachat.swift](https://github.com/tesseract-one/polkachat.swift).

If you have any suggestions, please, create an issue or submit a PR.

Thanks!
