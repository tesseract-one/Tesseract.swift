//
//  Future.swift
//
//
//  Created by Yehor Popovych on 15.07.2022.
//

import Foundation
import CTesseractUtils

public protocol CFuturePtr: CType {
    associatedtype CVal
    associatedtype Val
    
    var ptr: UnsafeRawPointer! { get set }
    
    // Consumes future. Will call free automatically
    func onComplete(cb: @escaping (CResult<Val>) -> Void) throws
    
    // Frees unconsumed future. Call it only if you don't want to use the future
    mutating func free() throws
    
    // Helpers for value converting
    static func convert(cvalue: inout CVal) -> CResult<Val>
    static func convert(value: inout Val) -> CResult<CVal>
    
    // Don't use this methods directly
    mutating func _onComplete(cb: @escaping (CResult<CVal>) -> Void)
    mutating func _setupSetOnCompleteFunc()
    mutating func _setupReleaseFunc()
    mutating func _release()
}

extension CFuturePtr {
    public init(_ cb: @escaping @Sendable () async throws -> Val) {
        self = Self._wrapAsync {
            do {
                return .success(try await cb())
            } catch let err as CError {
                return .failure(err)
            } catch {
                return .failure(.panic(reason: error.localizedDescription))
            }
        }
    }
    
    public init(_ cb: @escaping @Sendable () async -> CResult<Val>) {
        self = Self._wrapAsync(cb)
    }

    public var value: Val {
        get async throws {
            try await withUnsafeThrowingContinuation { cont in
                do {
                    try self.onComplete(cb: cont.resume)
                } catch {
                    cont.resume(with: .failure(error))
                }
            }
        }
    }
    
    public var result: CResult<Val> {
        get async {
            await withUnsafeContinuation { cont in
                do {
                    try self.onComplete(cb: cont.resume)
                } catch let err as CError {
                    cont.resume(returning: .failure(err))
                } catch {
                    cont.resume(returning:
                            .failure(.panic(reason: error.localizedDescription))
                    )
                }
            }
        }
    }
    
    // Should be mutating but has workaround for better API
    public func onComplete(cb: @escaping (CResult<Val>) -> Void) throws {
        guard self.ptr != nil else { throw CError.nullPtr }
        var this = self
        withUnsafePointer(to: self) { ptr in
            UnsafeMutablePointer(mutating: ptr)!.pointee.ptr = nil
        }
        this._onComplete {
            cb($0.flatMap { val in
                var val = val
                return Self.convert(cvalue: &val)
            })
        }
    }
    
    // Call it only if you don't want to wait for Future.
    public mutating func free() throws {
        guard self.ptr != nil else { throw CError.nullPtr }
        self._release()
        self.ptr = nil
    }
}

//extension CFuturePtr where CVal == Val {
//    static func convert(cvalue: inout CVal) -> CResult<Val> {
//        .success(cvalue)
//    }
//    static func convert(value: inout Val) -> CResult<CVal> {
//        .success(value)
//    }
//}

extension CFuturePtr where CVal: CPtr, Val == CVal.Val {
    public static func convert(cvalue: inout CVal) -> CResult<Val> {
        return .success(cvalue.owned())
    }
}

extension CFuturePtr
    where CVal: OptionProtocol,
          CVal.OWrapped: CPtr,
          Val == CVal.OWrapped.Val
{
    public static func convert(cvalue: inout CVal) -> CResult<Val> {
        switch cvalue.option {
        case .none: return .failure(.nullPtr)
        case .some(var val):
            let owned = val.owned()
            cvalue = CVal(val)
            return .success(owned)
        }
    }
}

extension CFuturePtr where Val: AsCPtrCopy, Val.CopyPtr == CVal {
    public static func convert(value: inout Val) -> CResult<CVal> {
        .success(value.copiedPtr())
    }
}

extension CFuturePtr where Val: AsCPtrOwn, Val.OwnPtr == CVal {
    static func convert(value: inout Val) -> CResult<CVal> {
        .success(value.ownedPtr())
    }
}

extension CFuturePtr
    where Val: AsCPtrCopy,
          CVal: OptionProtocol,
          Val.CopyPtr == CVal.OWrapped
{
    public static func convert(value: inout Val) -> CResult<CVal> {
        .success(CVal(value.copiedPtr()))
    }
}

extension CFuturePtr
    where Val: AsCPtrOwn,
          CVal: OptionProtocol,
          Val.OwnPtr == CVal.OWrapped
{
    static func convert(value: inout Val) -> CResult<CVal> {
        .success(CVal(value.ownedPtr()))
    }
}

extension CFuturePtr where Val: CValue, CVal == Val.CVal {
    public static func convert(cvalue: inout CVal) -> CResult<Val> {
        return .success(Val(cvalue: cvalue))
    }
    
    public static func convert(value: inout Val) -> CResult<CVal> {
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
}

private class CAsyncContext<V> {
    let semaphore: DispatchSemaphore
    var value: Optional<CResult<V>>
    var onComplete: Optional<(CResult<V>) -> Void>
    
    init() {
        self.semaphore = DispatchSemaphore(value: 1)
        self.value = nil
        self.onComplete = nil
    }
}

extension CFuturePtr {
    public func _withOnCompleteContext(
        _ cb: @escaping (CResult<CVal>) -> Void,
        _ fn: (UnsafeRawPointer) -> Void
    ) {
        let pointer = UnsafeMutablePointer<CFutureContext<Self>>.allocate(capacity: 1)
        pointer.initialize(to: CFutureContext(future: self, callback: cb))
        fn(UnsafeRawPointer(pointer))
    }
    
    public static func _onCompleteCallback(
        _ ctx: UnsafeRawPointer!,
        _ value: UnsafeMutablePointer<CVal>?,
        _ error: UnsafeMutablePointer<CTesseractUtils.CError>?
    ) {
        let ctx = ctx.assumingMemoryBound(to: CFutureContext<Self>.self)
        let callback = ctx.pointee.callback
        var future = ctx.pointee.future
        ctx.deallocate()
        defer { future._release() }
        if let error = error {
            callback(.failure(error.pointee.owned()))
        } else {
            callback(.success(value!.pointee))
        }
    }
    
    public static func _wrapAsync(_ fn: @escaping @Sendable () async -> CResult<Val>) -> Self {
        let context = CAsyncContext<CVal>()
        
        var future = Self()
        future.ptr = UnsafeRawPointer(Unmanaged.passRetained(context).toOpaque())
        future._setupSetOnCompleteFunc()
        future._setupReleaseFunc()
        
        Task.detached {
            let result = (await fn()).flatMap { (val) -> CResult<CVal> in
                var val = val
                return Self.convert(value: &val)
            }
            context.semaphore.wait()
            if let callback = context.onComplete {
                context.value = nil
                context.onComplete = nil
                context.semaphore.signal()
                callback(result)
            } else {
                context.value = result
                context.semaphore.signal()
            }
        }
        
        return future
    }
    
    public static func _setOnCompleteFunc(
        _ this: UnsafePointer<Self>!,
        _ ctx: UnsafeRawPointer?,
        _ cb: @escaping (UnsafeRawPointer?,
                         UnsafeMutablePointer<CVal>?,
                         UnsafeMutablePointer<CTesseractUtils.CError>?) -> ()
    ) {
        let context = Unmanaged<CAsyncContext<CVal>>
            .fromOpaque(this.pointee.ptr)
            .takeUnretainedValue()
        let newCb = { (res: CResult<CVal>) in
            switch res {
            case .failure(let err):
                var cerr = err.copiedPtr()
                cb(ctx, nil, &cerr)
            case .success(var val): cb(ctx, &val, nil)
            }
        }
        context.semaphore.wait()
        if let value = context.value {
            context.value = nil
            context.semaphore.signal()
            newCb(value)
        } else {
            context.onComplete = newCb
            context.semaphore.signal()
        }
    }
    
    public static func _release(_ this: UnsafeMutablePointer<Self>?) {
        print("SWIFT FUTURE RELEASE!!!!")
        if let ptr = this?.pointee.ptr {
            let _ = Unmanaged<CAsyncContext<CVal>>
                .fromOpaque(ptr)
                .takeRetainedValue()
            this!.pointee.ptr = nil
        }
    }
}
