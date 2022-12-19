//
//  SwiftPtr.swift
//  
//
//  Created by Yehor Popovych on 20.11.2022.
//

import Foundation
import CTesseractUtils

public protocol CSwiftDropPtr: CType {
    associatedtype SObject: AnyObject
    
    var ptr: CAnyDropPtr { get set }
    
    init(value object: SObject)
    
    func unowned() throws -> SObject
    mutating func owned() throws -> SObject
    
    mutating func free() throws
}

extension CSwiftDropPtr {
    public init(value object: SObject) {
        self = Self()
        self.ptr = .wrapped(object)
    }
    
    public func unowned() throws -> SObject {
        try self.ptr.unowned(SObject.self)
    }
    
    public mutating func owned() throws -> SObject {
        try self.ptr.owned(SObject.self)
    }
    
    public mutating func free() throws {
        try self.ptr.free()
    }
}

public protocol CSwiftAnyDropPtr: CType {
    var ptr: CAnyDropPtr { get set }
    
    init(value object: AnyObject)
    
    func unowned() throws -> AnyObject
    mutating func owned() throws -> AnyObject
    
    mutating func free() throws
}

extension CSwiftAnyDropPtr {
    public init(value object: AnyObject) {
        self = Self()
        self.ptr = .wrapped(object)
    }
    
    public func unowned() throws -> AnyObject {
        guard let obj = self.ptr.unowned() else {
            throw CError.nullPtr
        }
        return obj
    }
    
    public mutating func owned() throws -> AnyObject {
        try self.ptr.owned()
    }
    
    public mutating func free() throws {
        try self.ptr.free()
    }
}

extension UnsafePointer where Pointee: CSwiftDropPtr {
    public func unowned() throws -> Pointee.SObject {
        try self.pointee.unowned()
    }
}

extension UnsafeMutablePointer where Pointee: CSwiftDropPtr {
    public func unowned() throws -> Pointee.SObject  {
        try self.pointee.unowned()
    }
    
    public func owned() throws -> Pointee.SObject  {
        try self.pointee.owned()
    }
}

extension UnsafePointer where Pointee: CSwiftAnyDropPtr {
    public func unowned() throws -> AnyObject {
        try self.pointee.unowned()
    }
}

extension UnsafeMutablePointer where Pointee: CSwiftAnyDropPtr {
    public func unowned() throws -> AnyObject  {
        try self.pointee.unowned()
    }
    
    public func owned() throws -> AnyObject  {
        try self.pointee.owned()
    }
}

public extension SyncPtr_Void {
    func unowned() -> AnyObject {
        Unmanaged<AnyObject>.fromOpaque(self).takeUnretainedValue()
    }
    
    static func unowned(_ value: AnyObject) -> Self {
        UnsafeRawPointer(Unmanaged.passUnretained(value).toOpaque())
    }
    
    static func owned(_ value: AnyObject) -> Self {
        UnsafeRawPointer(Unmanaged.passRetained(value).toOpaque())
    }
}

public extension Optional where Wrapped == SyncPtr_Void {
    func unowned() -> AnyObject? {
        self?.unowned()
    }
    
    mutating func owned() -> AnyObject? {
        guard let ptr = self else { return nil }
        self = nil
        return Unmanaged<AnyObject>.fromOpaque(ptr).takeRetainedValue()
    }
    
    static func owned(_ value: AnyObject?) -> Self {
        value.map { UnsafeRawPointer(Unmanaged.passRetained($0).toOpaque()) }
    }
    
    static func unowned(_ value: AnyObject?) -> Self {
        value.map { UnsafeRawPointer(Unmanaged.passUnretained($0).toOpaque()) }
    }
}
