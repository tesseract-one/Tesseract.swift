//
//  Protocols.swift
//
//
//  Created by Yehor Popovych on 16.07.2022.
//

import Foundation
import CTesseractShared

// Basic type returned from C
public protocol CType {
    init()
}

// Type returned from C that should be deleted
public protocol CFree {
    mutating func free()
}

// Ref structure with pointers inside
public protocol CPtrRef {
    associatedtype SVal
    
    func copied() -> SVal
}

// Structure with pointers inside
public protocol CPtr: CPtrRef, CFree {
    mutating func owned() -> SVal
}

// Swift value which can be simply converted from C (static struct)
// Don't use it for pointers. For pointers CPtr should be used.
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
    
    func withRef<T>(_ fn: (Ref) throws -> T) rethrows -> T
}

// Swift value which can be referenced with CPtrRef value
public protocol AsCPtrRef {
    associatedtype RefPtr: CPtrRef
    
    func withPtrRef<T>(_ fn: (RefPtr) throws -> T) rethrows -> T
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
    
    func withRefRef<T>(_ fn: (UnsafeBufferPointer<Elem.Ref>) throws -> T) rethrows -> T
}

// Swift collection value which holds CPtrRef values
public protocol CollectionAsCPtrRefRef {
    associatedtype Elem: AsCPtrRef
    
    func withPtrRefRef<T>(_ fn: (UnsafeBufferPointer<Elem.RefPtr>) throws -> T) rethrows -> T
}

// Swift collection value which holds CPtrRef values
public protocol CollectionAsCPtrCopyRef {
    associatedtype Elem: AsCPtrCopy
    
    func withPtrCopyRef<T>(_ fn: (UnsafeBufferPointer<Elem.CopyPtr>) throws -> T) rethrows -> T
}
