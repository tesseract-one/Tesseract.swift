<p align="left">
	<a href="http://tesseract.one/">
		<img alt="Tesseract" src ="./.github/logo-horiz.svg" height=128/>
	</a>
</p>

# Tesseract Transports API

Transports in Tesseract can be implemented in Swift or Rust, and exported to Swift. If you have crossplatform transport (like WebSocket, WebRTC etc.) it's better to implement it once in Rust and export to the Swift. Apple unique transports can be implemented directly in Swift.

## Swift Transports API
Client and Wallet transports are different, so we have different sets of protocols for them.

### Client Transport
Client Transport should implement these protocols:
```swift
import TesseractTransportsClient // Client Transports SDK

// Main transport object
public protocol Transport: AnyObject, CoreConvertible<ClientTransport> {
    // Transport ID. Unique string like 'ipc' for IPC transport
    var id: String { get }

    // Check if protocol supported through transport. 
    func status(proto: String) async -> Status

    // Create new connection to the Wallet for provided protocol
    func connect(proto: String) -> any Connection
}

// Wallet connection
public protocol Connection: AnyObject, CoreConvertible<ClientConnection> {
    // Send data to the wallet
    func send(request: Data) async -> Result<(), TesseractError>

    // Receive response
    func receive() async -> Result<Data, TesseractError>
}
```

Workflow:
1. Tesseract checks if transport is working and supports needed protocol (wallet installed, bluetooth enabled, etc.) by calling `status` method.
2. Asks user to select transport based on their returned `Status` objects.
3. Calls `connect` method in selected transport to obtain new `Connection`.
4. Calls `send` method in `Connection` with request data and then `receive` to get response.

For example of implementation you can check [IPCTransportIOS](./Sources/TesseractTransportsClient/iOS/IPCTransportIOS.swift).

### Service Transport
Service transport should implement these protocols:

```swift
import TesseractTransportsService // Service Transports SDK

// Main Transport protocol
public protocol Transport: AnyObject, CoreConvertible<ServiceTransport> {

    // Called when Tesseract starts transport.
    // This is a place to start listening for requests
    // Returns object, that will be dropped on Tesseract deallocation.
    func bind(processor: TransportProcessor) -> any BoundTransport
}

// Helper object which will be dropped on Tesseract deallocation.
// Stop listening in this object deinit
public protocol BoundTransport: AnyObject, CoreConvertible<ServiceBoundTransport> {}
```

where `TransportProcessor` is an object with one public method:
```swift
func process(data: Data) async -> Result<Data, TesseractError>
```

Worklow:
1. In `bind` method transport should start listening for requests and store all needed context in its' `BoundTransport`.
2. When data arrives, it should pass it to the `process` method of the `TransportProcessor` instance, wait for response, and send it to the client.
3. When `BoundTransport` is deallocated, transport stops listening and drop `TransportProcessor` and context resources.

For example of implementation you can check [IPCTransportIOS](./Sources/TesseractTransportsService/iOS/IPCTransportIOS.swift).

## Rust Transports API

This documentation will focus on wrapping Rust transports to use them in Swift.

If you interested in implementing transports in Rust, check documentation in the [Main Tesseract.rs repo](https://github.com/tesseract-one/Tesseract.rs).

### Client Transport

On the client side 