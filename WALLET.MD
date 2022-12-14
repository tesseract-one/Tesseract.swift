# Tesseract on iOS for Wallet developers

Integration of Tesseract into your wallet allows any dApp to request your wallet to sign a transaction. Currently Tesseract enables native dApps to integrate with wallets through IPC, which from the user perspective is just a modal screen from the wallet.

## Getting started

Getting **Tesseract** to work in iOS wallet is different from everywhere else only by the transports set it supports.

Currently we provide IPC transport, which allows the wallets to present their screens on top of iOS applications on request and sign the transactions.

### Add Extension target

Add new Action Extension target to the project. This will be your Wallet interface for the dApps.

### Set up Rust

To add Rust, to your Wallet, please consider going through our guide [Setting up Rust](./RUST.MD). It contains the steps required to add Rust support to an iOS app + some useful interop utils description we've built.

Integrate Rust into your Action Extension target.

### Initialize transport and tesseract in Swift

```swift
import CWallet
import TesseractService

class ActionViewController: UIViewController {
    var context: ExtensionContextPtr!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let transport = IPCTransportIOS(self)

        self.context = wallet_extension_init(transport.asNative())
    }
```
where `wallet_extension_init` is exported from Rust as

```rust
use tesseract_utils::*;
use tesseract_service::*;

// Pointer to our Rust Context (will be saved in the Swift for calls). Returns it as a struct with void* inside.
#[repr(C)]
pub struct ExtensionContextPtr(SyncPtr<Void>);

#[no_mangle]
pub unsafe extern "C" fn wallet_extension_init(transport: transport::Transport) -> ManuallyDrop<ExtensionContextPtr> {
  tesseract_utils_init();
  // your initialization code
}
```

The rest stays exactly the same as it is described in the main repo of Tesseract ([THIS ONE](https://github.com/tesseract-one/Tesseract.rs/)) on this page [HERE](https://github.com/tesseract-one/Tesseract.rs/blob/master/docs/SERVICE.MD).

### Add supported network protocols

* Edit Action Extension attributes in its `Info.plist` and add supported ptorocols (in this example `test` protocol. UTI is `one.tesseract.test`)
```plist
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
			<string>SUBQUERY(extensionItems, $item, SUBQUERY($item.attachments, $att, ANY $att.registeredTypeIdentifiers UTI-CONFORMS-TO "one.tesseract.test").@count == $item.attachments.@count).@count == 1</string>
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
* Add URL scheme to your `Info.plist` of the Wallet target
```plist
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
			<string>one.tesseract.test</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>tesseract+test</string>
			</array>
		</dict>
	</array>
</dict>
</plist>
```

## Usage

* [Main Rust API documentation](https://github.com/tesseract-one/Tesseract.rs)
* [dApp developers documentation](./README.MD)

Once we publish the iOS wrappers, the doc will appear here.

## Examples

You can find the examples (**Demo Wallet** and a **Demo dApp**) in this repo [HERE](./examples).
