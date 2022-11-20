//
//  SwiftPtr.swift
//  
//
//  Created by Yehor Popovych on 20.11.2022.
//

import Foundation
import CTesseractUtils

public protocol AsVoidSwiftPtr: AnyObject {
    func ownedPtr() -> UnsafeRawPointer
    func unownedPtr() -> UnsafeRawPointer
    
    static func owned(_ ptr: UnsafeRawPointer!) -> Self
    static func unowned(_ ptr: UnsafeRawPointer!) -> Self
}

public protocol CSwiftPtr: CType {
    associatedtype SObject: AsVoidSwiftPtr
    
    var ptr: SyncPtr_Void! { get set }
    
    init(owned object: SObject)
    init(unowned object: SObject)
    
    func unowned() -> SObject
    mutating func owned() -> SObject
}

extension CSwiftPtr {
    public init(owned object: SObject) {
        self = Self()
        self.ptr = object.ownedPtr()
    }
    
    public init(unowned object: SObject) {
        self = Self()
        self.ptr = object.unownedPtr()
    }
    
    public func unowned() -> SObject {
        SObject.unowned(self.ptr)
    }
    
    public mutating func owned() -> SObject {
        SObject.owned(self.ptr)
    }
}

public protocol CSwiftAnyPtr: CType {
    var ptr: SyncPtr_Void! { get set }
    
    init(owned object: AnyObject)
    init(unowned object: AnyObject)
    
    func unowned() -> AnyObject
    mutating func owned() -> AnyObject
    
    func unowned<T: AnyObject>(_ type: T.Type) -> T?
    mutating func owned<T: AnyObject>(_ type: T.Type) -> T?
}

extension CSwiftAnyPtr {
    public init(owned object: AnyObject) {
        self = Self()
        self.ptr = .anyOwned(object)
    }
    
    public init(unowned object: AnyObject) {
        self = Self()
        self.ptr = .anyUnowned(object)
    }
    
    public func unowned() -> AnyObject {
        self.ptr.anyUnowned()
    }
    
    public mutating func owned() -> AnyObject {
        self.ptr.anyOwned()
    }
    
    public func unowned<T: AnyObject>(_ type: T.Type) -> T? {
        self.unowned() as? T
    }
    
    public mutating func owned<T: AnyObject>(_ type: T.Type) -> T? {
        self.owned() as? T
    }
}

extension UnsafePointer where Pointee: CSwiftPtr {
    public func unowned() -> Pointee.SObject {
        Pointee.SObject.unowned(self.pointee.ptr)
    }
}

extension UnsafeMutablePointer where Pointee: CSwiftPtr {
    public func unowned() -> Pointee.SObject  {
        Pointee.SObject.unowned(self.pointee.ptr)
    }
    
    public func owned() -> Pointee.SObject  {
        Pointee.SObject.owned(self.pointee.ptr)
    }
}

extension UnsafePointer where Pointee: CSwiftAnyPtr {
    public func unowned() -> AnyObject {
        self.pointee.ptr.anyUnowned()
    }
    
    public func unowned<T: AnyObject>(_ type: T.Type) -> T? {
        self.unowned() as? T
    }
}

extension UnsafeMutablePointer where Pointee: CSwiftAnyPtr {
    public func unowned() -> AnyObject {
        self.pointee.ptr.anyUnowned()
    }
    
    public func unowned<T: AnyObject>(_ type: T.Type) -> T? {
        self.unowned() as? T
    }
    
    public func owned() -> AnyObject {
        self.pointee.ptr.anyOwned()
    }
    
    public func owned<T: AnyObject>(_ type: T.Type) -> T? {
        self.owned() as? T
    }
}

public extension AsVoidSwiftPtr {
    func ownedPtr() -> UnsafeRawPointer {
        UnsafeRawPointer(Unmanaged.passRetained(self).toOpaque())
    }
    
    func unownedPtr() -> UnsafeRawPointer {
        UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())
    }
    
    static func owned(_ ptr: UnsafeRawPointer!) -> Self {
        Unmanaged<Self>.fromOpaque(ptr).takeRetainedValue()
    }

    static func unowned(_ ptr: UnsafeRawPointer!) -> Self {
        Unmanaged<Self>.fromOpaque(ptr).takeUnretainedValue()
    }
}

public extension SyncPtr_Void {
    func anyUnowned() -> AnyObject {
        Unmanaged<AnyObject>.fromOpaque(self).takeUnretainedValue()
    }
    
    mutating func anyOwned() -> AnyObject {
        Unmanaged<AnyObject>.fromOpaque(self).takeRetainedValue()
    }
    
    static func anyOwned(_ value: AnyObject) -> Self {
        UnsafeRawPointer(Unmanaged.passRetained(value).toOpaque())
    }
    
    static func anyUnowned(_ value: AnyObject) -> Self {
        UnsafeRawPointer(Unmanaged.passUnretained(value).toOpaque())
    }
}
