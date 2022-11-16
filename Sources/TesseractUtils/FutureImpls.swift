//
//  FutureImpls.swift
//
//
//  Created by Yehor Popovych on 21.07.2022.
//

import Foundation
import CTesseractUtils

extension CFutureVoid: CFuturePtr {
    public typealias CVal = Void
    public typealias Val = Void
    
    public mutating func _onComplete(cb: @escaping (CResult<CVal>) -> Void) {
        _withOnCompleteContext(cb) { ctx in
            self.set_on_complete(&self, ctx) { ctx, val, err in
                Self._onCompleteCallback(ctx, val?.assumingMemoryBound(to: Void.self), err)
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
    
    public static func convert(cvalue: inout Void) -> CResult<Void> {
        .success(())
    }
    
    public static func convert(value: inout Void) -> CResult<Void> {
        .success(())
    }
}

extension CFutureAnyPtr: CFuturePtr {
    public typealias CVal = CAnyPtr?
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
    
    public static func convert(cvalue: inout CVal) -> CResult<Val> {
        cvalue == nil ? .failure(.nullPtr) : .success(cvalue!)
    }
    
    public static func convert(value: inout Val) -> CResult<CVal> {
        .success(value)
    }
    
    public mutating func _onComplete(cb: @escaping (CResult<CVal>) -> Void) {
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

extension CFutureData: CFuturePtr {
    public typealias CVal = CData
    public typealias Val = Data
    
    public mutating func _onComplete(cb: @escaping (CResult<CVal>) -> Void) {
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


extension CFutureString: CFuturePtr {
    public typealias CVal = Optional<CString>
    public typealias Val = String
    
    public mutating func _onComplete(cb: @escaping (CResult<CVal>) -> Void) {
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

extension CFutureBool: CFuturePtr {
    public typealias CVal = Bool
    public typealias Val = Bool
    
    public mutating func _onComplete(cb: @escaping (CResult<CVal>) -> Void) {
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
