//
//  Option.swift
//  
//
//  Created by Ostap Danylovych on 16.06.2021.
//

import Foundation

extension Optional: CType {
    public init() { self = nil }
}

extension Optional: CPtr where Wrapped: CPtr {
    public typealias Val = Optional<Wrapped.Val>
    
    public func copied() -> Val {
        map { $0.copied() }
    }
    
    public mutating func owned() -> Val {
        switch self {
        case .none: return nil
        case .some(var val):
            let owned = val.owned()
            self = val
            return owned
        }
    }
    
    public mutating func free() {
        if var val = self {
            val.free()
            self = nil
        }
    }
}

extension Optional: CValue where Wrapped: CValue {
    public typealias CVal = Optional<Wrapped.CVal>
    
    public init(cvalue val: Wrapped.CVal?) {
        self = val.map(Wrapped.init)
    }
    public var asCValue: Wrapped.CVal? { map { $0.asCValue } }
}

extension Optional: AsCRef where Wrapped: AsCRef {
    public typealias Ref = Optional<Wrapped.Ref>
    
    public func withRef<T>(_ fn: @escaping (Ref) throws -> T) rethrows -> T {
        switch self {
        case .none: return try fn(nil)
        case .some(let val): return try val.withRef(fn)
        }
    }
}

extension Optional: AsCPtrRef where Wrapped: AsCPtrRef {
    public typealias RefPtr = Optional<Wrapped.RefPtr>
    
    public func withPtrRef<T>(_ fn: @escaping (RefPtr) throws -> T) rethrows -> T {
        switch self {
        case .none: return try fn(nil)
        case .some(let val): return try val.withPtrRef(fn)
        }
    }
}

extension Optional: AsCPtrCopy where Wrapped: AsCPtrCopy {
    public typealias CopyPtr = Optional<Wrapped.CopyPtr>
    
    public func copiedPtr() -> Optional<Wrapped.CopyPtr> {
        self.map { $0.copiedPtr() }
    }
}

extension Optional: AsCPtrOwn where Wrapped: AsCPtrOwn {
    public typealias MovePtr = Optional<Wrapped.OwnPtr>
    
    public mutating func ownedPtr() -> Optional<Wrapped.OwnPtr> {
        switch self {
        case .none: return nil
        case .some(var val):
            let owned = val.ownedPtr()
            self = val
            return owned
        }
    }
}

public protocol COption: CType, OptionProtocol where OWrapped == COpVal {
    associatedtype CTag: Equatable
    associatedtype COpVal: CType
    associatedtype SOpVal
    
    var tag: CTag { get set }
    var some: COpVal { get set }
    
    static var some: CTag { get }
    static var none: CTag { get }
}

extension COption {
    public init(_ val: Optional<COpVal>) {
        self.init()
        switch val {
        case .none: self.tag = Self.none
        case .some(let v):
            self.tag = Self.some
            self.some = v
        }
    }
    
    public var option: Optional<COpVal> { tag == Self.some ? self.some : nil }
}

extension COption where SOpVal: CValue, COpVal == SOpVal.CVal {
    public func get() -> Optional<SOpVal> {
        option.map { SOpVal(cvalue: $0) }
    }
}

extension COption where COpVal: CPtr, SOpVal == COpVal.Val {
    public func copied() -> SOpVal? {
        option.map { $0.copied() }
    }
    
    public mutating func owned() -> SOpVal? {
        if tag == Self.some {
            let value = self.some.owned()
            self.tag = Self.none
            return value
        }
        return nil
    }
    
    public mutating func free() {
        if tag == Self.some {
            self.some.free()
            self.tag = Self.none
        }
    }
}

extension Optional where Wrapped: CValue {
    public func cOption<O: COption>() -> O where O.COpVal == Wrapped.CVal {
        O(self?.asCValue)
    }
}

extension Optional where Wrapped: AsCPtrCopy {
    public func copiedOptionPtr<O: COption>() -> O where O.COpVal == Wrapped.CopyPtr {
        O(self?.copiedPtr())
    }
}

extension Optional where Wrapped: AsCPtrOwn {
    public mutating func ownedOptionPtr<O: COption>() -> O where O.COpVal == Wrapped.OwnPtr {
        switch self {
        case .none: return O(nil)
        case .some(var val):
            let owned = val.ownedPtr()
            self = val
            return O(owned)
        }
    }
}

extension Optional where Wrapped: AsCRef {
    public func withOptionRef<O: COption, T>(
        _ fn: @escaping (O) throws -> T
    ) rethrows -> T where O.COpVal == Wrapped.Ref {
        try withRef { try fn(O($0)) }
    }
}

extension Optional where Wrapped: AsCPtrRef {
    public func withOptionPtrRef<O: COption, T>(
        _ fn: @escaping (O) throws -> T
    ) rethrows -> T where O.COpVal == Wrapped.RefPtr {
        try withPtrRef { try fn(O($0)) }
    }
}

public protocol OptionProtocol {
    associatedtype OWrapped
    init(_ option: Optional<OWrapped>)
    var option: Optional<OWrapped> { get }
}

extension Optional: OptionProtocol {
    public typealias OWrapped = Wrapped
    public init(_ option: Optional<Wrapped>) {
        self = option
    }
    public var option: Optional<OWrapped> { self }
}
