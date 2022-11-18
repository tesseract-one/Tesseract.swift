//
//  FutureImpls.swift
//
//
//  Created by Yehor Popovych on 21.07.2022.
//

import Foundation
import CTesseractUtils

extension CFutureValue_Nothing: CFutureValueValue {
    public typealias Val = Nothing
    
    public static var valueTag: CFutureValue_Nothing_Tag {
        CFutureValue_Nothing_Value_Nothing
    }
    
    public static var errorTag: CFutureValue_Nothing_Tag {
        CFutureValue_Nothing_Error_Nothing
    }
    
    public static var noneTag: CFutureValue_Nothing_Tag {
        CFutureValue_Nothing_None_Nothing
    }
}

extension CFutureNothing: CFuturePtr {
    public typealias CVal = CFutureValue_Nothing
    public typealias Val = Void
    
    public mutating func _onComplete(cb: @escaping (CResult<CVal.Val>) -> Void) -> CVal {
        _withOnCompleteContext(cb) { ctx in
            self.set_on_complete(&self, ctx) { ctx, val, err in
                Self._onCompleteCallback(ctx, val, err)
            }
        }
    }
    
    public mutating func _setupSetOnCompleteFunc() {
        self.set_on_complete = { this, ctx, cb in
            Self._setOnCompleteFunc(this, ctx) { this, val, err in
                cb?(this, val, err)
            }
        }
    }
    
    public mutating func _setupReleaseFunc() {
        self.release = { Self._release($0) }
    }
    
    public mutating func _release() {
        self.release(&self)
    }
    
    public static func convert(cvalue: inout Nothing) -> CResult<Void> {
        .success(())
    }
    
    public static func convert(value: inout Void) -> CResult<Nothing> {
        .success(.nothing)
    }
}

extension CFutureValue_CAnyPtr: CFutureValuePtr {
    public typealias PtrVal = CAnyPtr
    
    public static var valueTag: CFutureValue_CAnyPtr_Tag {
        CFutureValue_CAnyPtr_Value_CAnyPtr
    }

    public static var errorTag: CFutureValue_CAnyPtr_Tag {
        CFutureValue_CAnyPtr_Error_CAnyPtr
    }

    public static var noneTag: CFutureValue_CAnyPtr_Tag {
        CFutureValue_CAnyPtr_None_CAnyPtr
    }
}

extension CFutureAnyPtr: CFuturePtr {
    public typealias CVal = CFutureValue_CAnyPtr
    public typealias Val = CAnyPtr
    
    public init<T: AsAnyPtrCopy>(copying cb: @escaping @Sendable () async throws -> T) {
        self.init { try await cb().copiedAnyPtr() }
    }
    
    public init<T: AsAnyPtrOwn>(owning cb: @escaping @Sendable () async throws -> T) {
        self.init {
            var val = try await cb()
            return val.ownedAnyPtr()
        }
    }
    
    public init<T: AsAnyPtrCopy>(copying cb: @escaping @Sendable () async -> CResult<T>) {
        self.init { await cb().map { $0.copiedAnyPtr() } }
    }
    
    public init<T: AsAnyPtrOwn>(owning cb: @escaping @Sendable () async -> CResult<T>) {
        self.init { await cb().map { val in
            var val = val
            return val.ownedAnyPtr()
        } }
    }
    
    public func value<T: FromAnyPtr>(_ type: T.Type) async throws -> T {
        var val = try await self.value
        return type.init(anyptr: &val)
    }
    
    public func result<T: FromAnyPtr>(_ type: T.Type) async -> CResult<T> {
        await self.result.map { val in
            var val = val
            return type.init(anyptr: &val)
        }
    }
    
    public static func convert(cvalue: inout CVal.Val) -> CResult<Val> {
        cvalue == nil ? .failure(.nullPtr) : .success(cvalue!)
    }
    
    public static func convert(value: inout Val) -> CResult<CVal.Val> {
        .success(value)
    }
    
    public mutating func _onComplete(cb: @escaping (CResult<CVal.Val>) -> Void) -> CVal {
        _withOnCompleteContext(cb) { ctx in
            self.set_on_complete(&self, ctx) { ctx, val, err in
                Self._onCompleteCallback(ctx, val, err)
            }
        }
    }
    
    public mutating func _setupSetOnCompleteFunc() {
        self.set_on_complete = { this, ctx, cb in
            Self._setOnCompleteFunc(this, ctx) { this, val, err in
                cb?(this, val, err)
            }
        }
    }
    
    public mutating func _setupReleaseFunc() {
        self.release = { Self._release($0) }
    }
    
    public mutating func _release() {
        self.release(&self)
    }
}

extension CFutureValue_CData: CFutureValueValue {
    public typealias Val = CData
    
    public static var valueTag: CFutureValue_CData_Tag {
        CFutureValue_CData_Value_CData
    }
    
    public static var errorTag: CFutureValue_CData_Tag {
        CFutureValue_CData_Error_CData
    }
    
    public static var noneTag: CFutureValue_CData_Tag {
        CFutureValue_CData_None_CData
    }
}

extension CFutureData: CFuturePtr {
    public typealias CVal = CFutureValue_CData
    public typealias Val = Data
    
    public mutating func _onComplete(cb: @escaping (CResult<CVal.Val>) -> Void) -> CVal {
        _withOnCompleteContext(cb) { ctx in
            self.set_on_complete(&self, ctx) { ctx, val, err in
                Self._onCompleteCallback(ctx, val, err)
            }
        }
    }
    
    public mutating func _setupSetOnCompleteFunc() {
        self.set_on_complete = { this, ctx, cb in
            Self._setOnCompleteFunc(this, ctx) { this, val, err in
                cb?(this, val, err)
            }
        }
    }
    
    public mutating func _setupReleaseFunc() {
        self.release = { Self._release($0) }
    }
    
    public mutating func _release() {
        self.release(&self)
    }
}

extension CFutureValue_CString: CFutureValuePtr {
    public typealias PtrVal = CString
    
    public static var valueTag: CFutureValue_CString_Tag {
        CFutureValue_CString_Value_CString
    }
    
    public static var errorTag: CFutureValue_CString_Tag {
        CFutureValue_CString_Error_CString
    }
    
    public static var noneTag: CFutureValue_CString_Tag {
        CFutureValue_CString_None_CString
    }
}

extension CFutureString: CFuturePtr {
    public typealias CVal = CFutureValue_CString
    public typealias Val = String
    
    public mutating func _onComplete(cb: @escaping (CResult<CVal.Val>) -> Void) -> CVal {
        _withOnCompleteContext(cb) { ctx in
            self.set_on_complete(&self, ctx) { ctx, val, err in
                Self._onCompleteCallback(ctx, val, err)
            }
        }
    }
    
    public mutating func _setupSetOnCompleteFunc() {
        self.set_on_complete = { this, ctx, cb in
            Self._setOnCompleteFunc(this, ctx) { this, val, err in
                cb?(this, val, err)
            }
        }
    }
    
    public mutating func _setupReleaseFunc() {
        self.release = { Self._release($0) }
    }
    
    public mutating func _release() {
        self.release(&self)
    }
}

extension CFutureValue_bool: CFutureValueValue {
    public typealias Val = Bool
    
    public static var valueTag: CFutureValue_bool_Tag {
        CFutureValue_bool_Value_bool
    }
    
    public static var errorTag: CFutureValue_bool_Tag {
        CFutureValue_bool_Error_bool
    }
    
    public static var noneTag: CFutureValue_bool_Tag {
        CFutureValue_bool_None_bool
    }
}

extension CFutureBool: CFuturePtr {
    public typealias CVal = CFutureValue_bool
    public typealias Val = Bool
    
    public mutating func _onComplete(cb: @escaping (CResult<CVal.Val>) -> Void) -> CVal {
        _withOnCompleteContext(cb) { ctx in
            self.set_on_complete(&self, ctx) { ctx, val, err in
                Self._onCompleteCallback(ctx, val, err)
            }
        }
    }
    
    public mutating func _setupSetOnCompleteFunc() {
        self.set_on_complete = { this, ctx, cb in
            Self._setOnCompleteFunc(this, ctx) { this, val, err in
                cb?(this, val, err)
            }
        }
    }
    
    public mutating func _setupReleaseFunc() {
        self.release = { Self._release($0) }
    }
    
    public mutating func _release() {
        self.release(&self)
    }
}
