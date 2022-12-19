//
//  NativeTransport.swift
//  TesseractClient
//
//  Created by Yehor Popovych on 07.10.2022.
//

import Foundation
import TesseractUtils
import CTesseractClient

extension CFutureValue_Status: CFutureValueValue {
    public typealias Val = CTesseractClient.Status
    
    public static var valueTag: CFutureValue_Status_Tag {
        CFutureValue_Status_Value_Status
    }
    
    public static var errorTag: CFutureValue_Status_Tag {
        CFutureValue_Status_Error_Status
    }
    
    public static var noneTag: CFutureValue_Status_Tag {
        CFutureValue_Status_None_Status
    }
}

extension CFutureStatus: CFuturePtr {
    public typealias CVal = CFutureValue_Status
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
            cvalue.tag = Status_Ready
        case .error(let err):
            cvalue.tag = Status_Error
            cvalue.error = err.copiedPtr()
        case .unavailable(let str):
            cvalue.tag = Status_Unavailable
            cvalue.unavailable = str.copiedPtr()
        }
        return .success(cvalue)
    }
}

extension NativeTransport: CSwiftAnyDropPtr {}
extension NativeConnection: CSwiftAnyDropPtr {}

private func transport_id(self: UnsafePointer<NativeTransport>!) -> CString? {
    (try! self.unowned() as! Transport).id.copiedPtr()
}

private func transport_status(
    self: UnsafePointer<NativeTransport>!,
    proto: CStringRef!
) -> CFutureStatus {
    CFutureStatus {
        try await (self.unowned() as! Transport).status(proto: proto!.copied())
    }
}

private func transport_connect(
    self: UnsafePointer<NativeTransport>!,
    proto: CStringRef!
) -> NativeConnection {
    (try! self.unowned() as! Transport).connect(proto: proto!.copied()).asNative()
}

private func connection_send(self: UnsafePointer<NativeConnection>!, data: UnsafePointer<UInt8>!, len: UInt) -> CFutureNothing {
    let data = Data(bytes: UnsafeRawPointer(data), count: Int(len))
    return CFutureNothing {
        try await (self.unowned() as! Connection).send(request: data)
    }
}

private func connection_receive(self: UnsafePointer<NativeConnection>!) -> CFutureData {
    return CFutureData {
        try await (self.unowned() as! Connection).receive()
    }
}

extension NativeTransport {
    public init(transport: Transport) {
        self = Self(value: transport)
        self.id = transport_id
        self.status = transport_status
        self.connect = transport_connect
    }
}

extension NativeConnection {
    public init(connection: Connection) {
        self = Self(value: connection)
        self.send = connection_send
        self.receive = connection_receive
    }
}

extension Transport {
    public func asNative() -> NativeTransport {
        NativeTransport(transport: self)
    }
}

extension Connection {
    public func asNative() -> NativeConnection {
        NativeConnection(connection: self)
    }
}
