//
//  Future.swift
//
//
//  Created by Yehor Popovych on 15.07.2022.
//

import Foundation
import CTesseract

public protocol CFutureValue: CType {
    associatedtype Val
    associatedtype Tag: Equatable
    
    var tag: Tag { get set }
    var error: CTesseract.CError { get set }
    
    var _value: Val { get set }
    
    static var valueTag: Tag { get }
    static var errorTag: Tag { get }
    static var noneTag: Tag { get }
}

extension CFutureValue {
    public var isNone: Bool {
        self.tag == Self.noneTag
    }
    
    public var isSome: Bool {
        self.tag == Self.valueTag || self.tag == Self.errorTag
    }
    
    public init(_ result: CResult<Val>) {
        switch result {
        case .failure(let err): self = Self.error(err.copiedPtr())
        case .success(let val): self = Self.value(val)
        }
    }
    
    public mutating func asResult() -> CResult<Val>? {
        switch self.tag {
        case Self.valueTag: return .success(self._value)
        case Self.errorTag: return .failure(self.error.owned())
        default: return nil
        }
    }
    
    public static var none: Self {
        var val = Self()
        val.tag = Self.noneTag
        return val
    }
    
    public static func error(_ error: CTesseract.CError) -> Self {
        var val = Self()
        val.tag = Self.errorTag
        val.error = error
        return val
    }
    
    public static func value(_ value: Val) -> Self {
        var val = Self()
        val.tag = Self.valueTag
        val._value = value
        return val
    }
}

public protocol CFutureValueValue: CFutureValue {
    var value: Val { get set }
}

extension CFutureValueValue {
    public var _value: Val { get { value } set { value = newValue } }
}

public protocol CFutureValuePtr: CFutureValue where Val == PtrVal? {
    associatedtype PtrVal
    
    var value: PtrVal! { get set }
}

extension CFutureValuePtr {
    public var _value: Val { get { value } set { value = newValue } }
}

public protocol CFuturePtr: CType {
    associatedtype CVal: CFutureValue
    associatedtype Val
    
    var ptr: CAnyDropPtr { get set }
    
    // Consumes future. Will call free automatically
    func onComplete(cb: @escaping (CResult<Val>) -> Void) throws -> CResult<Val>?
    
    // Frees unconsumed future. Call it only if you don't want to use the future
    mutating func free() -> CResult<Void>
    
    // Helpers for value converting
    static func convert(cvalue: inout CVal.Val) -> CResult<Val>
    static func convert(value: inout Val) -> CResult<CVal.Val>
    
    // Don't use this methods directly
    mutating func _onComplete(cb: @escaping (CResult<CVal.Val>) -> Void) -> CVal
    mutating func _setupSetOnCompleteFunc()
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
                    if let value = try self.onComplete(cb: cont.resume) {
                        cont.resume(with: value)
                    }
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
                    if let value = try self.onComplete(cb: cont.resume) {
                        cont.resume(with: .success(value))
                    }
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
    public func onComplete(cb: @escaping (CResult<Val>) -> Void) throws -> CResult<Val>? {
        guard !self.ptr.isNull else { throw CError.nullPtr }
        var this = self
        withUnsafePointer(to: self) { ptr in
            UnsafeMutablePointer(mutating: ptr)!.pointee.ptr.ptr = nil
        }
        var value = this._onComplete {
            cb($0.flatMap { val in
                var val = val
                return Self.convert(cvalue: &val)
            })
        }
        return value.asResult()?.flatMap { val in
            var val = val
            return Self.convert(cvalue: &val)
        }
    }
    
    // Call it only if you don't want to wait for the Future.
    public mutating func free() -> CResult<Void> {
        self.ptr.free()
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

extension CFuturePtr where CVal.Val: CPtr, Val == CVal.Val.Val {
    public static func convert(cvalue: inout CVal.Val) -> CResult<Val> {
        return .success(cvalue.owned())
    }
}

extension CFuturePtr
    where CVal.Val: OptionProtocol,
          CVal.Val.OWrapped: CPtr,
          Val == CVal.Val.OWrapped.Val
{
    public static func convert(cvalue: inout CVal.Val) -> CResult<Val> {
        switch cvalue.option {
        case .none: return .failure(.nullPtr)
        case .some(var val):
            let owned = val.owned()
            cvalue = CVal.Val(val)
            return .success(owned)
        }
    }
}

extension CFuturePtr where Val: AsCPtrCopy, Val.CopyPtr == CVal.Val {
    public static func convert(value: inout Val) -> CResult<CVal.Val> {
        .success(value.copiedPtr())
    }
}

extension CFuturePtr where Val: AsCPtrOwn, Val.OwnPtr == CVal.Val {
    static func convert(value: inout Val) -> CResult<CVal.Val> {
        .success(value.ownedPtr())
    }
}

extension CFuturePtr
    where Val: AsCPtrCopy,
          CVal.Val: OptionProtocol,
          Val.CopyPtr == CVal.Val.OWrapped
{
    public static func convert(value: inout Val) -> CResult<CVal.Val> {
        .success(CVal.Val(value.copiedPtr()))
    }
}

extension CFuturePtr
    where Val: AsCPtrOwn,
          CVal.Val: OptionProtocol,
          Val.OwnPtr == CVal.Val.OWrapped
{
    static func convert(value: inout Val) -> CResult<CVal.Val> {
        .success(CVal.Val(value.ownedPtr()))
    }
}

extension CFuturePtr where Val: CValue, CVal.Val == Val.CVal {
    public static func convert(cvalue: inout CVal.Val) -> CResult<Val> {
        return .success(Val(cvalue: cvalue))
    }
    
    public static func convert(value: inout Val) -> CResult<CVal.Val> {
        return .success(value.asCValue)
    }
}

private struct CFutureContext<F> where F: CFuturePtr {
    var future: F
    let callback: (CResult<F.CVal.Val>) -> Void
    
    init(future: F, callback: @escaping (CResult<F.CVal.Val>) -> Void) {
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
        _ cb: @escaping (CResult<CVal.Val>) -> Void,
        _ fn: (UnsafeRawPointer) -> CVal
    ) -> CVal {
        let pointer = CFutureContext(future: self, callback: cb).ownedPtr()
        let value = fn(pointer)
        if value.isSome { // We have value already. Context is non needed
            var this = self
            let _ = CFutureContext<Self>.take(pointer)
            try! this.free().get()
        }
        return value
    }
    
    public static func _onCompleteCallback(
        _ ctx: UnsafeRawPointer!,
        _ value: UnsafeMutablePointer<CVal.Val>?,
        _ error: UnsafeMutablePointer<CTesseract.CError>?
    ) {
        var ctx = CFutureContext<Self>.take(ctx)
        defer { try! ctx.future.free().get() }
        if let error = error {
            ctx.callback(.failure(error.pointee.owned()))
        } else {
            ctx.callback(.success(value!.pointee))
        }
    }
    
    public static func _wrapAsync(_ fn: @escaping @Sendable () async -> CResult<Val>) -> Self {
        let context = CAsyncContext<CVal.Val>()
        
        var future = Self()
        future.ptr = .wrapped(context)
        future._setupSetOnCompleteFunc()
        
        // Will be detached anyway because there is no Task context.
        Task.detached {
            let result = (await fn()).flatMap { (val) -> CResult<CVal.Val> in
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
        _ cb: @escaping (UnsafeRawPointer?,
                         UnsafeMutablePointer<CVal.Val>?,
                         UnsafeMutablePointer<CTesseract.CError>?) -> Void
    ) -> CVal {
        let context = try! this.pointee.ptr.unowned(CAsyncContext<CVal.Val>.self).get()
        
        let newCb = { (res: CResult<CVal.Val>) in
            switch res {
            case .failure(let err):
                var cerr = err.copiedPtr()
                cb(ctx, nil, &cerr)
            case .success(var val): cb(ctx, &val, nil)
            }
        }
        context.lock()
        switch context.state {
        case .resolved:
            context.unlock()
            fatalError("Future is already resolved!")
        case .callback(_):
            context.unlock()
            fatalError("Future is already has callback!")
        case .empty:
            context.state = .callback(newCb)
            context.unlock()
            return CVal.none
        case .value(let value):
            context.state = .resolved
            context.unlock()
            return CVal(value)
        }
    }
}
