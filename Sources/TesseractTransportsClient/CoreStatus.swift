//
//  CoreStatus.swift
//  
//
//  Created by Yehor Popovych on 23/11/2023.
//

import Foundation
import CTesseractShared
#if COCOAPODS
@_exported import TesseractShared
#else
@_exported import TesseractTransportsShared
#endif

extension ClientStatus: CPtr, CType {
    public typealias Val = Status
    
    public func copied() -> Status {
        switch tag {
        case ClientStatus_Ready: return .ready
        case ClientStatus_Error:
            return .error(TesseractError(cError: self.error.copied()))
        case ClientStatus_Unavailable:
            return .unavailable(self.unavailable.copied())
        default: fatalError("Unknown tag: \(tag)")
        }
    }
    
    public mutating func owned() -> Status {
        switch tag {
        case ClientStatus_Ready: return .ready
        case ClientStatus_Error:
            return .error(TesseractError(cError: self.error.owned()))
        case ClientStatus_Unavailable:
            return .unavailable(self.unavailable.owned())
        default: fatalError("Unknown tag: \(tag)")
        }
    }
    
    public mutating func free() {
        switch tag {
        case ClientStatus_Error: self.error.free()
        case ClientStatus_Unavailable: self.unavailable.free()
        default: break
        }
    }
}

extension Status: AsCPtrCopy {
    public typealias CopyPtr = ClientStatus
    
    public func copiedPtr() -> CopyPtr {
        var cvalue = CopyPtr()
        switch self {
        case .ready:
            cvalue.tag = ClientStatus_Ready
        case .error(let err):
            cvalue.tag = ClientStatus_Error
            cvalue.error = err.cError.copiedPtr()
        case .unavailable(let str):
            cvalue.tag = ClientStatus_Unavailable
            cvalue.unavailable = str.copiedPtr()
        }
        return cvalue
    }
}

extension Status: CoreConvertible {
    public func toCore() -> ClientStatus { copiedPtr() }
}

extension CFutureClientStatus: CFuturePtr {
    public typealias CVal = ClientStatus
    public typealias SVal = Status
    
    mutating public func _onComplete(cb: @escaping (CResult<CVal>) -> Void) -> CResult<CVal>? {
        _withOnCompleteContext(cb) { ctx, value, error in
            self.set_on_complete(&self, ctx, value, error) { ctx, val, err in
                Self._onCompleteCallback(ctx, val, err)
            }
        }
    }
    
    mutating public func _setupSetOnCompleteFunc() {
        self.set_on_complete = { this, ctx, value, error, cb in
            Self._setOnCompleteFunc(this, ctx, value, error) { this, val, err in
                cb?(this, val, err)
            }
        }
    }
}
