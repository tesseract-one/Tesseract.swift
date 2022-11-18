//
//  NativeTransport.swift
//  TestApp
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
    
    mutating public func _setupReleaseFunc() {
        self.release = { Self._release($0) }
    }
    
    mutating public func _release() {
        self.release(&self)
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

private func transport_id(self: UnsafePointer<NativeTransport>!) -> CString? {
    self.unowned().id.copiedPtr()
}

private func transport_status(
    self: UnsafePointer<NativeTransport>!,
    proto: CStringRef!
) -> CFutureStatus {
    CFutureStatus {
        await self.unowned().status(proto: proto!.copied())
    }
}

private func transport_connect(
    self: UnsafePointer<NativeTransport>!,
    proto: CStringRef!
) -> NativeConnection {
    self.unowned().connect(proto: proto!.copied()).asNative()
}

private func transport_release(self: UnsafeMutablePointer<NativeTransport>!) {
    let _ = self.owned()
}

private func connection_send(self: UnsafePointer<NativeConnection>!, data: UnsafePointer<UInt8>!, len: UInt) -> CFutureNothing {
    let data = Data(bytes: UnsafeRawPointer(data), count: Int(len))
    return CFutureNothing {
        try await self.unowned().send(request: data)
    }
}

private func connection_receive(self: UnsafePointer<NativeConnection>!) -> CFutureData {
    return CFutureData {
        try await self.unowned().receive()
    }
}

private func connection_release(self: UnsafeMutablePointer<NativeConnection>!) {
    let _ = self.owned()
}

extension UnsafePointer where Pointee == NativeTransport {
    public func unowned() -> Transport {
        Unmanaged<AnyObject>.fromOpaque(self.pointee.ptr).takeUnretainedValue() as! Transport
    }
}

extension UnsafeMutablePointer where Pointee == NativeTransport {
    public func unowned() -> Transport {
        Unmanaged<AnyObject>.fromOpaque(self.pointee.ptr).takeUnretainedValue() as! Transport
    }
    
    public func owned() -> Transport {
        Unmanaged<AnyObject>.fromOpaque(self.pointee.ptr).takeRetainedValue() as! Transport
    }
}

extension UnsafePointer where Pointee == NativeConnection {
    public func unowned() -> Connection {
        Unmanaged<AnyObject>.fromOpaque(self.pointee.ptr).takeUnretainedValue() as! Connection
    }
}

extension UnsafeMutablePointer where Pointee == NativeConnection {
    public func unowned() -> Connection {
        Unmanaged<AnyObject>.fromOpaque(self.pointee.ptr).takeUnretainedValue() as! Connection
    }
    
    public func owned() -> Connection {
        Unmanaged<AnyObject>.fromOpaque(self.pointee.ptr).takeRetainedValue() as! Connection
    }
}

extension Transport {
    public func asNative() -> NativeTransport {
        NativeTransport(
            ptr: Unmanaged.passRetained(self as AnyObject).toOpaque(),
            id: transport_id,
            status: transport_status,
            connect: transport_connect,
            release: transport_release
        )
    }
}

extension Connection {
    public func asNative() -> NativeConnection {
        NativeConnection(
            ptr: Unmanaged.passRetained(self as AnyObject).toOpaque(),
            send: connection_send,
            receive: connection_receive,
            release: connection_release
        )
    }
}
