//
//  SwiftPtr.swift
//  
//
//  Created by Yehor Popovych on 20.11.2022.
//

import Foundation
import CTesseractUtils

public protocol SAsVoidPtr: AnyObject {
    func ownedPtr() -> UnsafeRawPointer
    func unownedPtr() -> UnsafeRawPointer
    
    static func owned(_ ptr: UnsafeRawPointer!) -> Self
    static func unowned(_ ptr: UnsafeRawPointer!) -> Self
}

public extension SAsVoidPtr {
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
