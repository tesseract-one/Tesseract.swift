<p align="center">
	<a href="http://tesseract.one/">
		<img alt="Tesseract" src ="./.github/logo.svg" height=256/>
	</a>
</p>

# Tesseract Swift

**Tesseract.swift** provides Swift APIs for [Tesseract](https://github.com/tesseract-one/), a dApp-Wallet bridge designed to make dApp/wallet communication on mobile devices simple and natural without compromising decentralization and security

If you are looking for Tesseract docs for another language/OS, please, consider one of the following:

* [General info](https://github.com/tesseract-one/)
* [Tesseract for Android](https://github.com/tesseract-one/Tesseract.android)
* [Tesseract shared Core (Rust)](https://github.com/tesseract-one/Tesseract.rs)

## Getting started

Tesseract provides two sets of APIs, one for a dApp that wants to connect to the wallets and one for the wallets that want to serve the dApps.

Here is how a typical Tesseract workflow looks like:

<table>
<tr>
<th> dApp </th>
<th> Wallet </th>
</tr>
<tr>
<td>

```swift
//initialize Tesseract with default config
let tesseract = Tesseract.default

//indicate what blockchain are we gonna use
let substrateService = tesseract.service(SubstrateService.self)

//at this point Tesseract connects to the
//wallet and the wallet presents the user
//with its screen, asking if the user
//wants to share their public key to a dApp
let account = try await substrateService.getAccount(.sr25519)
```

</td>
<td>

```swift
//Inside the Wallet Tesseract serves requests
//from the dApps as long as the reference is kept alive
//save it somewhere in the Extension instance
let tesseract = Tesseract()
    .transport(IPCTransportIOS(self)) //add iOS IPC transport
    .service(MySubstrateService())
//MySubstrateService instance methods
//will be called when a dApp asks for something
```

</td>
</tr>
</table>

## Details

Because using Tesseract in Tesseract in a dApp and in a wallet is very different by nature (essentially communicating as a client and a service), the detailed documentation is split into two documents:

* [Tesseract for dApp developers](./DAPP.MD)
* [Tesseract for Wallet developers](./WALLET.MD)

## Examples

If you'd like to see examples of Tesseract integration, please, check:

* [dev-wallet.swift](https://github.com/tesseract-one/dev-wallet.swift) - for wallets
* polkachat.swift - for dApps, TBD

## More

Just in case, you'd like to use Tesseract on iOS via Rust APIs. It's also possible. Consider checking one of the following:

* [Using Tesseract on iOS in Rust](./RUST.MD)
* [Developer Wallet in Rust](https://github.com/tesseract-one/dev-wallet)

## Roadmap

* [x] v0.1 - IPC transport for iOS - connect dApp/Wallet on the same device
* [x] v0.2 - demo dApp and Wallet
* [x] v0.3 - Susbtrate protocol support
* [x] v0.4 - [dev-wallet.swift](https://github.com/tesseract-one/dev-wallet.swift) test implementation
* [x] v0.5 - first Swift libraries release version
* [ ] v1.0 - support of everything mobile dApps need

## License

Tesseract.swift can be used, distributed and modified under [the Apache 2.0 license](LICENSE).
