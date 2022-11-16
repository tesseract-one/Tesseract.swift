//
//  Protocols.swift
//
//
//  Created by Yehor Popovych on 16.07.2022.
//

import Foundation
import CTesseractUtils

// Basic type returned from C
public protocol CType {
    init()
}

// Structure with pointers inside
public protocol CPtr {
    associatedtype Val
    
    func copied() -> Val
    mutating func owned() -> Val
    mutating func free()
}

// Swift value which can be simply converted from C (static struct)
// Don't use it for pointers. For pointers CPtr and CPtrMove should be used.
public protocol CValue {
    associatedtype CVal: CType
    
    init(cvalue val: CVal)
    var asCValue: CVal { get }
}

// primitives
public extension CValue where CVal == Self {
    init(cvalue val: CVal) { self = val }
    var asCValue: CVal { self }
}

// Swift value which can be referenced with C
public protocol AsCRef {
    associatedtype Ref
    
    func withRef<T>(_ fn: @escaping (Ref) throws -> T) rethrows -> T
}

// Swift value which can be referenced with CPtr value
public protocol AsCPtrRef {
    associatedtype RefPtr: CPtr
    
    func withPtrRef<T>(_ fn: @escaping (RefPtr) throws -> T) rethrows -> T
}

// Swift value which can be copied to CPtr value
public protocol AsCPtrCopy {
    associatedtype CopyPtr: CPtr
    
    func copiedPtr() -> CopyPtr
}

// Swift value which can be moved to CPtr value
public protocol AsCPtrOwn {
    associatedtype OwnPtr: CPtr
    
    mutating func ownedPtr() -> OwnPtr
}

// Swift collection value which holds CRef values
public protocol CollectionAsCRefRef {
    associatedtype Elem: AsCRef
    
    func withRefRef<T>(_ fn: @escaping (UnsafeBufferPointer<Elem.Ref>) throws -> T) rethrows -> T
}

// Swift collection value which holds CPtrRef values
public protocol CollectionAsCPtrRefRef {
    associatedtype Elem: AsCPtrRef
    
    func withPtrRefRef<T>(_ fn: @escaping (UnsafeBufferPointer<Elem.RefPtr>) throws -> T) rethrows -> T
}

// Swift collection value which holds CPtrRef values
public protocol CollectionAsCPtrCopyRef {
    associatedtype Elem: AsCPtrCopy
    
    func withPtrCopyRef<T>(_ fn: @escaping (UnsafeBufferPointer<Elem.CopyPtr>) throws -> T) rethrows -> T
}
