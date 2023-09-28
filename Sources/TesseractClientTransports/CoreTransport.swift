//
//  CoreTransport.swift
//  TesseractClient
//
//  Created by Yehor Popovych on 07.10.2022.
//

import Foundation
import CTesseract
@_exported import TesseractShared

extension CFutureValue_ClientStatus: CFutureValueValue {
    public typealias Val = ClientStatus
    
    public static var valueTag: CFutureValue_ClientStatus_Tag {
        CFutureValue_ClientStatus_Value_ClientStatus
    }
    
    public static var errorTag: CFutureValue_ClientStatus_Tag {
        CFutureValue_ClientStatus_Error_ClientStatus
    }
    
    public static var noneTag: CFutureValue_ClientStatus_Tag {
        CFutureValue_ClientStatus_None_ClientStatus
    }
}

extension CFutureClientStatus: CFuturePtr {
    public typealias CVal = CFutureValue_ClientStatus
    public typealias Val = Status
    
    mutating public func _onComplete(cb: @escaping (CResult<CVal.Val>) -> Void) -> CVal {
        _withOnCompleteContext(cb) { ctx in
            self.set_on_complete(&self, ctx) { ctx, val, err in
                Self._onCompleteCallback(ctx, val, err)
            }
        }
    }
    
    mutating public func _setupSetOnCompleteFunc() {
        self.set_on_complete = { this, ctx, cb in
            Self._setOnCompleteFunc(this, ctx) { this, val, err in
                cb?(this, val, err)
            }
        }
    }
    
    public static func convert(cvalue: inout CVal.Val) -> CResult<Val> {
        CResult.failure(.panic(reason: "One way conversion only"))
    }
    
    public static func convert(value: inout Val) -> CResult<CVal.Val> {
        var cvalue = CVal.Val()
        switch value {
        case .ready:
            cvalue.tag = ClientStatus_Ready
        case .error(let err):
            cvalue.tag = ClientStatus_Error
            cvalue.error = err.copiedPtr()
        case .unavailable(let str):
            cvalue.tag = ClientStatus_Unavailable
            cvalue.unavailable = str.copiedPtr()
        }
        return .success(cvalue)
    }
}

extension ClientTransport: CSwiftAnyDropPtr {}
extension ClientConnection: CSwiftAnyDropPtr {}

private func transport_id(self: UnsafePointer<ClientTransport>!) -> CString? {
    try! self.unowned(Transport.self).get().id.copiedPtr()
}

private func transport_status(
    self: UnsafePointer<ClientTransport>!,
    proto: CStringRef!
) -> CFutureClientStatus {
    let proto = proto!.copied()
    return CFutureClientStatus {
        await self.unowned(Transport.self).asyncFlatMap {
            .success(await $0.status(proto: proto))
        }
    }
}

private func transport_connect(
    self: UnsafePointer<ClientTransport>!,
    proto: CStringRef!
) -> ClientConnection {
    try! self.unowned(Transport.self).get().connect(proto: proto.copied()).toCore()
}

private func connection_send(self: UnsafePointer<ClientConnection>!,
                             data: UnsafePointer<UInt8>!,
                             len: UInt) -> CFutureNothing
{
    let data = Data(bytes: UnsafeRawPointer(data), count: Int(len))
    return CFutureNothing {
        await self.unowned(Connection.self).asyncFlatMap {
            await $0.send(request: data)
        }
    }
}

private func connection_receive(self: UnsafePointer<ClientConnection>!) -> CFutureData {
    return CFutureData {
        await self.unowned(Connection.self).asyncFlatMap {
            await $0.receive()
        }
    }
}

extension ClientTransport {
    public init(transport: Transport) {
        self = Self(value: transport)
        self.id = transport_id
        self.status = transport_status
        self.connect = transport_connect
    }
}

extension ClientConnection {
    public init(connection: Connection) {
        self = Self(value: connection)
        self.send = connection_send
        self.receive = connection_receive
    }
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
