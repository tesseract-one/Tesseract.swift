<p align="left">
	<a href="http://tesseract.one/">
		<img alt="Tesseract" src ="./.github/logo-horiz.svg" height=128/>
	</a>
</p>

# Tesseract on iOS for Wallet developers

Integration of Tesseract into your wallet allows any dApp to request your wallet to sign a transaction. Currently Tesseract enables native dApps to integrate with wallets through IPC, which from the user perspective is just a modal screen from the wallet.

## Getting started

Getting **Tesseract** to work in iOS wallet is different from everywhere else only by the transports set it supports.

Currently we provide IPC transport, which allows the wallets to present their screens on top of iOS applications on request and sign the transactions.

## Installation

### Add Extension target

Add new Action Extension target to the your Wallet project. This will be your Wallet interface for the dApps.

### Add Tesseract.swift dependency

1. Add [Tesseract.swift](https://github.com/tesseract-one/Tesseract.swift) repository dependency through `File` -> `Add Package` menu in Xcode.
2. Add `TesseractService` framework dependency to your Extension target.

### Add supported network protocols to your targets

* Edit Extension target attributes in its `Info.plist` and add supported ptorocols (in this example `test` and `substrate-v1` protocol.)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>NSExtension</key>
	<dict>
		<key>NSExtensionAttributes</key>
		<dict>
			<key>NSExtensionServiceRoleType</key>
			<string>NSExtensionServiceRoleTypeEditor</string>
			<key>NSExtensionActivationRule</key>
			<string>
				SUBQUERY(
					extensionItems, 
					$item,
					SUBQUERY(
						$item.attachments,
						$att,
						ANY $att.registeredTypeIdentifiers UTI-CONFORMS-TO "one.tesseract.test"
						OR ANY $att.registeredTypeIdentifiers UTI-CONFORMS-TO "one.tesseract.substrate-v1"
					).@count == $item.attachments.@count
				).@count == 1
			</string>
			<key>NSExtensionServiceAllowsFinderPreviewItem</key>
			<true/>
			<key>NSExtensionServiceAllowsTouchBarItem</key>
			<true/>
			<key>NSExtensionServiceFinderPreviewIconName</key>
			<string>NSActionTemplate</string>
			<key>NSExtensionServiceTouchBarBezelColorName</key>
			<string>TouchBarBezel</string>
			<key>NSExtensionServiceTouchBarIconName</key>
			<string>NSActionTemplate</string>
		</dict>
		<key>NSExtensionMainStoryboard</key>
		<string>MainInterface</string>
		<key>NSExtensionPointIdentifier</key>
		<string>com.apple.ui-services</string>
	</dict>
</dict>
</plist>
```
* Add URL schemes to your `Info.plist` of the Wallet target
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
			<key>CFBundleURLName</key>
			<string>one.tesseract</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>tesseract+test</string>
				<string>tesseract+substrate-v1</string>
			</array>
		</dict>
	</array>
</dict>
</plist>
```

## Services

Through Tesseract, wallets serve the dApps by providing services accessible from the outside. A service implementation is responsible for understanding requests, providing the user with confirmation UI and replying back.

To make Tesseract work in your wallet, you need to describe, how exactly the wallet wants to react when a dApp needs something.

In Tesseract this is done via services. One service per blockchain protocol. The way the wallet signs transactions i.e. for Subsrate and for Ethereum is very different, thus every service has its own API to implement.

Let's take a look at the `TestService` implementation example from [Examples](./Examples/Swift/Extension/TestSigningService.swift).:

```swift
import TesseractService

protocol TestSigningServiceDelegate: AnyObject {
    func acceptTx(tx: String) async throws -> Bool
}

class TestSigningService: TestService {
    var signature: String
    weak var delegate: TestSigningServiceDelegate?
    
    init(delegate: TestSigningServiceDelegate, signature: String) {
        self.delegate = delegate
        self.signature = signature
    }
    
    func signTransation(req: String) async throws -> String {
        guard let delegate = self.delegate else {
            throw TesseractError.null(TestSigningServiceDelegate.self)
        }
        guard try await delegate.acceptTx(tx: req) else {
            throw TesseractError.cancelled
        }
        return req + signature
    }
}
```

The wallet is responsible to present the user with the relevant UI and reply with a response in case the user agrees to proced. Otherwise just throw `TesseractError.cancelled`. Or any other error if, in example, the request data is malformed.

## Transport

For now Tesseract supports only iOS IPC transport which called `IPCTransportIOS`.

Transport should be created and provided to the `Tesseract` instance. See example bellow.

Full documentation on Transports development can be found here: [Transports How To](./TRANSPORTS.MD)

## Initialization

Here is a typical Tesseract initialization snippet (the example is taken from [Example](./Examples/Swift/Extension/ActionViewController.swift)):

`ActionViewController` is a root ViewController provided in Extension `Info.plist` file.

```swift
import TesseractService

class ActionViewController: UIViewController, TestSigningServiceDelegate {
    var tesseract: Tesseract!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let data = WalletData()
        let service = TestSigningService(delegate: self, signature: data.signature)
        
        self.tesseract = try! Tesseract()
            .transport(IPCTransportIOS(self))
            .service(service)
            // add all supported services through .service() calls
    }

    @MainActor
    func acceptTx(tx: String) async throws -> Bool {
        // Show UI
    }
}
```

## Conclusion

We tried our best to present an API as easy for the wallet developer as we could and handled all the edge cases we know of inside the library. At least we improved it to the point that it satisfied us while building the [dev-wallet.swift](https://github.com/tesseract-one/dev-wallet.swift).

If you have any suggestions, please, create an issue or submit a PR.

Thanks!
