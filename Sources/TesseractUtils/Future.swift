//
//  Future.swift
//
//
//  Created by Yehor Popovych on 15.07.2022.
//

import Foundation
import CTesseractShared

public protocol CFuturePtr: CType, CFree {
    associatedtype CVal: CType
    associatedtype SVal
    
    var ptr: CAnyDropPtr { get set }
    
    // Consumes future. Will call free automatically
    func onComplete(cb: @escaping (CResult<SVal>) -> Void) -> CResult<SVal>?
    
    // Helpers for value converting
    static func convert(cvalue: inout CVal) -> CResult<SVal>
    static func convert(value: inout SVal) -> CResult<CVal>
    
    // Don't use this methods directly
    mutating func _onComplete(cb: @escaping (CResult<CVal>) -> Void) -> CResult<CVal>?
    mutating func _setupSetOnCompleteFunc()
}

extension CFuturePtr {
    public init(_ cb: @escaping @Sendable () async throws -> SVal) {
        self = Self._wrapAsync {
            do {
                return .success(try await cb())
            } catch let err as CError {
                return .failure(err)
            } catch let err as CErrorConvertible {
                return .failure(err.cError)
            } catch {
                return .failure(.swift(error: error as NSError))
            }
        }
    }
    
    public init(_ cb: @escaping @Sendable () async -> CResult<SVal>) {
        self = Self._wrapAsync(cb)
    }
    
    public init<E: CErrorConvertible>(_ cb: @escaping @Sendable () async -> Result<SVal, E>) {
        self = Self._wrapAsync { await cb().mapError { $0.cError } }
    }

    public var value: SVal {
        get async throws {
            try await withUnsafeThrowingContinuation { cont in
                if let value = self.onComplete(cb: cont.resume) {
                    cont.resume(with: value)
                }
            }
        }
    }
    
    public var result: CResult<SVal> {
        get async {
            await withUnsafeContinuation { cont in
                if let value = self.onComplete(cb: cont.resume) {
                    cont.resume(returning: value)
                }
            }
        }
    }
    
    // Should be mutating but has workaround for better API
    public func onComplete(cb: @escaping (CResult<SVal>) -> Void) -> CResult<SVal>? {
        guard !self.ptr.isNull else { return .failure(.null(Self.self)) }
        var this = self
        withUnsafePointer(to: self) { ptr in
            UnsafeMutablePointer(mutating: ptr)!.pointee.ptr.ptr = nil
        }
        return this._onComplete {
            cb($0.flatMap { val in
                var val = val
                return Self.convert(cvalue: &val)
            })
        }.map { $0.flatMap { val in
            var val = val
            return Self.convert(cvalue: &val)
        }}
    }
    
    // Call it only if you don't want to wait for the Future.
    public mutating func free() {
        self.ptr.free()
    }
}

extension CFuturePtr where CVal: CPtr, SVal == CVal.SVal {
    public static func convert(cvalue: inout CVal) -> CResult<SVal> {
        return .success(cvalue.owned())
    }
}

extension CFuturePtr
    where CVal: OptionProtocol,
          CVal.OWrapped: CPtr,
          SVal == CVal.OWrapped.SVal
{
    public static func convert(cvalue: inout CVal) -> CResult<SVal> {
        switch cvalue.option {
        case .none: return .failure(.null(Self.self))
        case .some(var val):
            let owned = val.owned()
            cvalue = CVal(val)
            return .success(owned)
        }
    }
}

extension CFuturePtr where SVal: AsCPtrCopy, SVal.CopyPtr == CVal {
    public static func convert(value: inout SVal) -> CResult<CVal> {
        .success(value.copiedPtr())
    }
}

extension CFuturePtr where SVal: AsCPtrOwn, SVal.OwnPtr == CVal {
    static func convert(value: inout SVal) -> CResult<CVal> {
        .success(value.ownedPtr())
    }
}

extension CFuturePtr
    where SVal: AsCPtrCopy,
          CVal: OptionProtocol,
          SVal.CopyPtr == CVal.OWrapped
{
    public static func convert(value: inout SVal) -> CResult<CVal> {
        .success(CVal(value.copiedPtr()))
    }
}

extension CFuturePtr
    where SVal: OptionProtocol,
          SVal.OWrapped: AsCPtrCopy,
          CVal: OptionProtocol,
          SVal.OWrapped.CopyPtr == CVal.OWrapped
{
    public static func convert(value: inout SVal) -> CResult<CVal> {
        .success(CVal(value.option?.copiedPtr()))
    }
}

extension CFuturePtr
    where SVal: AsCPtrOwn,
          CVal: OptionProtocol,
          SVal.OwnPtr == CVal.OWrapped
{
    static func convert(value: inout SVal) -> CResult<CVal> {
        .success(CVal(value.ownedPtr()))
    }
}

extension CFuturePtr
    where SVal: OptionProtocol,
          SVal.OWrapped: AsCPtrOwn,
          CVal: OptionProtocol,
          SVal.OWrapped.OwnPtr == CVal.OWrapped
{
    static func convert(value: inout SVal) -> CResult<CVal> {
        switch value.option {
        case .none: return .success(CVal(nil))
        case .some(var val):
            let owned = val.ownedPtr()
            value = SVal(val)
            return .success(CVal(owned))
        }
    }
}

extension CFuturePtr where SVal: CValue, CVal == SVal.CVal {
    public static func convert(cvalue: inout CVal) -> CResult<SVal> {
        return .success(SVal(cvalue: cvalue))
    }
    
    public static func convert(value: inout SVal) -> CResult<CVal> {
        return .success(value.asCValue)
    }
}

private struct CFutureContext<F> where F: CFuturePtr {
    var future: F
    let callback: (CResult<F.CVal>) -> Void
    
    init(future: F, callback: @escaping (CResult<F.CVal>) -> Void) {
        self.future = future
        self.callback = callback
    }
    
    func ownedPtr() -> UnsafeRawPointer {
        let pointer = UnsafeMutablePointer<Self>.allocate(capacity: 1)
        pointer.initialize(to: self)
        return UnsafeRawPointer(pointer)
    }
    
    static func take(_ ptr: UnsafeRawPointer!) -> Self {
        let ctx = ptr.assumingMemoryBound(to: Self.self)
        defer { ctx.deallocate() }
        return ctx.pointee
    }
}

private class CAsyncContext<V> {
    enum State<V> {
        case empty
        case value(CResult<V>)
        case callback((CResult<V>) -> Void)
        case resolved
    }
    
    private let semaphore: DispatchSemaphore
    internal var state: State<V>
    
    init() {
        self.semaphore = DispatchSemaphore(value: 1)
        self.state = .empty
    }
    
    func lock() {
        semaphore.wait()
    }
    
    func unlock() {
        semaphore.signal()
    }
}

extension CFuturePtr {
    public func _withOnCompleteContext(
        _ cb: @escaping (CResult<CVal>) -> Void,
        _ fn: (UnsafeRawPointer,
               UnsafeMutablePointer<CVal>,
               UnsafeMutablePointer<CTesseractShared.CError>) -> COptionResponseResult
    ) -> CResult<CVal>? {
        let pointer = CFutureContext(future: self, callback: cb).ownedPtr()
        
        var value = CVal()
        var error = CTesseractShared.CError()
        let result: CResult<CVal>?
        
        switch fn(pointer, &value, &error) {
        case COptionResponseResult_None: result = nil
        case COptionResponseResult_Error: result = .failure(error.owned())
        case COptionResponseResult_Some: result = .success(value)
        default: fatalError("unknown option result")
        }
        
        if result != nil { // We have value already. Context is non needed
            var this = self
            let _ = CFutureContext<Self>.take(pointer)
            this.free()
        }
        return result
    }
    
    public static func _onCompleteCallback(
        _ ctx: UnsafeRawPointer!,
        _ value: UnsafeMutablePointer<CVal>?,
        _ error: UnsafeMutablePointer<CTesseractShared.CError>?
    ) {
        var ctx = CFutureContext<Self>.take(ctx)
        defer { ctx.future.free() }
        if let error = error {
            ctx.callback(.failure(error.pointee.owned()))
        } else {
            ctx.callback(.success(value!.pointee))
        }
    }
    
    public static func _wrapAsync(_ fn: @escaping @Sendable () async -> CResult<SVal>) -> Self {
        let context = CAsyncContext<CVal>()
        
        var future = Self()
        future.ptr = .wrapped(context)
        future._setupSetOnCompleteFunc()
        
        // Will be detached anyway because there is no Task context.
        Task.detached {
            let result = (await fn()).flatMap { (val) -> CResult<CVal> in
                var val = val
                return Self.convert(value: &val)
            }
            context.lock()
            switch context.state {
            case .resolved:
                context.unlock()
                fatalError("Future is already resolved!")
            case .value(_):
                context.unlock()
                fatalError("Future is already has value!")
            case .empty:
                context.state = .value(result)
                context.unlock()
            case .callback(let callback):
                context.state = .resolved
                context.unlock()
                callback(result)
            }
        }
        
        return future
    }
    
    public static func _setOnCompleteFunc(
        _ this: UnsafePointer<Self>!,
        _ ctx: UnsafeRawPointer?,
        _ value: UnsafeMutablePointer<CVal>!,
        _ error: UnsafeMutablePointer<CTesseractShared.CError>!,
        _ cb: @escaping (UnsafeRawPointer?,
                         UnsafeMutablePointer<CVal>?,
                         UnsafeMutablePointer<CTesseractShared.CError>?) -> Void
    ) -> COptionResponseResult {
        let context = try! this.pointee.ptr.unowned(CAsyncContext<CVal>.self).get()
        
        let newCb = { (res: CResult<CVal>) in
            switch res {
            case .failure(let err):
                var cerr = err.copiedPtr()
                cb(ctx, nil, &cerr)
            case .success(var val): cb(ctx, &val, nil)
            }
        }
        
        context.lock(); defer { context.unlock() }
        switch context.state {
        case .resolved: fatalError("Future is already resolved!")
        case .callback(_): fatalError("Future is already has callback!")
        case .empty:
            context.state = .callback(newCb)
            return COptionResponseResult_None
        case .value(let stored):
            context.state = .resolved
            switch stored {
            case .failure(let err):
                error.pointee = err.copiedPtr()
                return COptionResponseResult_Error
            case .success(let val):
                value.pointee = val
                return COptionResponseResult_Some
            }
        }
    }
}
