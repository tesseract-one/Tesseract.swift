//
//  CoreTransport.swift
//  TesseractClient
//
//  Created by Yehor Popovych on 07.10.2022.
//

import Foundation
import CTesseractShared
#if COCOAPODS
@_exported import TesseractShared
#else
@_exported import TesseractTransportsShared
#endif

public typealias CoreTransport = AutoFree<ClientTransport> & CoreConvertible<ClientTransport>

public extension AutoFree where Ptr == ClientTransport {
    func toCore() -> ClientTransport { take() }
}

extension ClientTransport: CAnyObjectPtr {}
extension ClientConnection: CAnyObjectPtr {}

private func transport_id(self: UnsafePointer<ClientTransport>!) -> CString {
    try! self.unowned((any Transport).self).get().id.copiedPtr()
}

private func transport_status(
    self: UnsafePointer<ClientTransport>!,
    proto: CStringRef!
) -> CFutureClientStatus {
    let proto = proto.copied()
    return CFutureClientStatus {
        await self.unowned((any Transport).self).asyncFlatMap {
            .success(await $0.status(proto: proto))
        }
    }
}

private func transport_connect(
    self: UnsafePointer<ClientTransport>!,
    proto: CStringRef!
) -> ClientConnection {
    try! self.unowned((any Transport).self)
        .get().connect(proto: proto.copied()).toCore()
}

private func connection_send(self: UnsafePointer<ClientConnection>!,
                             data: CDataRef) -> CFutureNothing
{
    let data = data.copied()
    return CFutureNothing {
        await self.unowned((any Connection).self).castError().asyncFlatMap {
            await $0.send(request: data)
        }
    }
}

private func connection_receive(self: UnsafePointer<ClientConnection>!) -> CFutureData {
    return CFutureData {
        await self.unowned((any Connection).self).castError().asyncFlatMap {
            await $0.receive()
        }
    }
}

extension ClientTransport {
    public init(transport: any Transport) {
        self = Self(value: transport)
        self.id = transport_id
        self.status = transport_status
        self.connect = transport_connect
    }
}

extension ClientConnection {
    public init(connection: any Connection) {
        self = Self(value: connection)
        self.send = connection_send
        self.receive = connection_receive
    }
}

extension ClientTransport: CoreConvertible {
    public func toCore() -> ClientTransport { self }
}

extension Transport {
    public func toCore() -> ClientTransport {
        ClientTransport(transport: self)
    }
}

extension Connection {
    public func toCore() -> ClientConnection {
        ClientConnection(connection: self)
    }
}
