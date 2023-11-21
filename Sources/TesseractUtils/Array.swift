//
//  Array.swift
//  
//
//  Created by Yehor Popovych on 13.05.2021.
//

import Foundation

public protocol CArrayPtrRef: CType, CPtrRef where RefVal == [SElement] {
    associatedtype CElement
    associatedtype SElement
    
    init(ptr: UnsafePointer<CElement>!, len: UInt)
    
    var ptr: UnsafePointer<CElement>! { get set }
    var len: UInt { get }
}

public protocol CArrayPtr: CType, CPtr where Val == [SElement] {
    associatedtype CElement
    associatedtype SElement
    
    init(ptr: UnsafePointer<CElement>!, len: UInt)
    
    var ptr: UnsafePointer<CElement>! { get set }
    var len: UInt { get }
}

extension CArrayPtrRef {
    public var bufferPtr: UnsafeBufferPointer<CElement> {
        UnsafeBufferPointer(start: ptr, count: Int(len))
    }
}

extension CArrayPtr {
    public init(buffer: UnsafeBufferPointer<CElement>) {
        self.init(ptr: buffer.baseAddress, len: UInt(buffer.count))
    }
    
    public init(buffer: UnsafeMutableBufferPointer<CElement>) {
        self.init(ptr: buffer.baseAddress, len: UInt(buffer.count))
    }
    
    public var bufferPtr: UnsafeBufferPointer<CElement> {
        UnsafeBufferPointer(start: ptr, count: Int(len))
    }
}

extension UnsafeBufferPointer {
    public func arrayPtr<A: CArrayPtr>() -> A where A.CElement == Element {
        A(buffer: self)
    }
}

extension UnsafeMutableBufferPointer where Element == UInt8 {
    public func arrayPtr<A: CArrayPtr>() -> A where A.CElement == Element {
        A(buffer: self)
    }
}

public protocol CCopyArrayPtrRef: CArrayPtrRef where CElement == SElement {}

extension CCopyArrayPtrRef {
    public func copied() -> RefVal { Array(bufferPtr) }
}

public protocol CCopyArrayPtr: CArrayPtr where CElement == SElement {}

extension CCopyArrayPtr {
    public func copied() -> Val { Array(bufferPtr) }

    public mutating func owned() -> Val {
        defer { self.free() }
        return self.copied()
    }
}

public protocol CCopyConvertArrayPtrRef: CArrayPtrRef {
    static func convert(element: CElement) -> SElement
}

extension CCopyConvertArrayPtrRef {
    public func copied() -> RefVal {
        bufferPtr.map { Self.convert(element: $0) }
    }
}

public protocol CCopyConvertArrayPtr: CArrayPtr {
    static func convert(element: CElement) -> SElement
}

extension CCopyConvertArrayPtr {
    public func copied() -> Val {
        bufferPtr.map { Self.convert(element: $0) }
    }

    public mutating func owned() -> Val {
        defer { self.free() }
        return self.copied()
    }
}

public protocol CValueArrayPtrRef: CCopyConvertArrayPtrRef
    where CElement: CValue, SElement == CElement.CVal {}

extension CValueArrayPtrRef {
    public static func convert(element: CElement) -> SElement {
        element.asCValue
    }
}

public protocol CValueArrayPtr: CCopyConvertArrayPtr
    where CElement: CValue, SElement == CElement.CVal {}

extension CValueArrayPtr {
    public static func convert(element: CElement) -> SElement {
        element.asCValue
    }
}

public protocol CPtrArrayPtrRef: CArrayPtrRef
    where CElement: CPtr, SElement == CElement.Val {}

extension CPtrArrayPtrRef {
    public func copied() -> RefVal {
        bufferPtr.map { $0.copied() }
    }
}

public protocol CPtrArrayPtr: CArrayPtr
    where CElement: CPtr, SElement == CElement.Val {}

extension CPtrArrayPtr {
    public func copied() -> Val {
        bufferPtr.map { $0.copied() }
    }

    public mutating func owned() -> Val {
        defer { self.free() }
        let memory = UnsafeMutableBufferPointer(
            start: UnsafeMutablePointer(mutating: ptr),
            count: Int(len)
        )
        var result = Array<SElement>()
        result.reserveCapacity(memory.count)
        for (indx, var elem) in memory.enumerated() {
            result.append(elem.owned())
            memory[indx] = elem
        }
        return result
    }
}

public protocol ArrayAsCValueRef: Collection, AsCRef
    where
        Element: CValue,
        Ref == UnsafeBufferPointer<Element.CVal> {}

extension ArrayAsCValueRef {
    public func withRef<T>(_ fn: (Ref) throws -> T) rethrows -> T {
        try map { $0.asCValue }.withUnsafeBufferPointer {
            try fn($0)
        }
    }
}

public protocol ArrayAsCRefRef: Collection, CollectionAsCRefRef
    where Elem == Element {}

extension ArrayAsCRefRef {
    public func withRefRef<T>(
        _ fn: (UnsafeBufferPointer<Elem.Ref>) throws -> T
    ) rethrows -> T {
        let buffer = UnsafeMutableBufferPointer<Elem.Ref>
            .allocate(capacity: count)
        return try refMap(buffer: buffer, current: startIndex) { ref in
            let val = try fn(ref)
            buffer.deallocate()
            return val
        }
    }
    
    private func refMap<T>(
        buffer: UnsafeMutableBufferPointer<Elem.Ref>,
        current: Self.Index,
        fn: (UnsafeBufferPointer<Elem.Ref>) throws -> T) rethrows -> T
    {
        guard current != endIndex else {
            return try fn(UnsafeBufferPointer(buffer))
        }
        return try self[current].withRef { ref in
            buffer[distance(from: startIndex, to: current)] = ref
            return try self.refMap(buffer: buffer,
                                   current: index(after: current),
                                   fn: fn)
        }
    }
}

public protocol ArrayAsCPtrRef: Collection, CollectionAsCPtrRefRef
    where Elem == Element {}

extension ArrayAsCPtrRef {
    public func withPtrRefRef<T>(_ fn: (UnsafeBufferPointer<Elem.RefPtr>) throws -> T) rethrows -> T {
        let buffer = UnsafeMutableBufferPointer<Elem.RefPtr>
            .allocate(capacity: count)
        return try refPtrMap(buffer: buffer, current: startIndex) { ref in
            let val = try fn(ref)
            buffer.deallocate()
            return val
        }
    }
    
    private func refPtrMap<T>(
        buffer: UnsafeMutableBufferPointer<Elem.RefPtr>,
        current: Self.Index,
        fn: (UnsafeBufferPointer<Elem.RefPtr>) throws -> T) rethrows -> T
    {
        guard current != endIndex else {
            return try fn(UnsafeBufferPointer(buffer))
        }
        return try self[current].withPtrRef { ref in
            buffer[distance(from: startIndex, to: current)] = ref
            return try self.refPtrMap(buffer: buffer,
                                      current: index(after: current),
                                      fn: fn)
        }
    }
}

extension Array: AsCRef where Element: CValue {
    public typealias Ref = UnsafeBufferPointer<Element.CVal>
}
extension Array: ArrayAsCValueRef where Element: CValue {}

extension Array: CollectionAsCRefRef where Element: AsCRef {
    public typealias Elem = Element
}
extension Array: ArrayAsCRefRef where Element: AsCRef {}

extension Array: CollectionAsCPtrRefRef where Element: AsCPtrRef {
    public typealias Elem = Element
}
extension Array: ArrayAsCPtrRef where Element: AsCPtrRef {}

extension Set: AsCRef where Element: CValue {
    public typealias Ref = UnsafeBufferPointer<Element.CVal>
}
extension Set: ArrayAsCValueRef where Element: CValue {}

extension Set: CollectionAsCRefRef where Element: AsCRef {
    public typealias Elem = Element
}
extension Set: ArrayAsCRefRef where Element: AsCRef {}

extension Set: CollectionAsCPtrRefRef where Element: AsCPtrRef {
    public typealias Elem = Element
}
extension Set: ArrayAsCPtrRef where Element: AsCPtrRef {}
