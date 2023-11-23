//
//  AutoFree.swift
//  
//
//  Created by Yehor Popovych on 23/11/2023.
//

import Foundation
import CTesseractShared

open class AutoFree<Ptr: CType & CFree> {
    private var _ptr: Ptr?
    
    public convenience init<E: CErrorInitializable>(
        error: E.Type,
        initializer: (UnsafeMutablePointer<Ptr>,
                      UnsafeMutablePointer<CTesseractShared.CError>) -> Bool
    ) throws {
        let ptr = try CResult<Ptr>.wrap(ccall: initializer).castError(error).get()
        self.init(ptr: ptr)
    }
    
    public init(ptr: Ptr) {
        _ptr = ptr
    }
    
    public func use<R>(_ fn: (inout Ptr) throws -> R) rethrows -> R {
        guard _ptr != nil else { fatalError("Null pointer: \(Ptr.self)") }
        return try fn(&_ptr!)
    }
    
    public func ptr<R>(_ fn: (UnsafePointer<Ptr>) throws -> R) rethrows -> R {
        guard _ptr != nil else { fatalError("Null pointer: \(Ptr.self)") }
        return try fn(&_ptr!)
    }
    
    public func mutPtr<R>(_ fn: (UnsafeMutablePointer<Ptr>) throws -> R) rethrows -> R {
        guard _ptr != nil else { fatalError("Null pointer: \(Ptr.self)") }
        return try fn(&_ptr!)
    }
    
    public func take() -> Ptr {
        guard _ptr != nil else { fatalError("Null pointer: \(Ptr.self)") }
        defer { _ptr = nil }
        return _ptr!
    }
    
    deinit {
        if _ptr != nil { _ptr!.free() }
    }
}
