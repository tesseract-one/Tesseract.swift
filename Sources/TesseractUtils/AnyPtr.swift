//
//  AnyPtr.swift
//  
//
//  Created by Yehor Popovych on 16.12.2022.
//

import Foundation
import CTesseract

extension CAnyDropPtr: CType {}

extension CAnyDropPtr {
    public init(value: AnyObject) {
        self = Self(
            ptr: .owned(value),
            drop: any_ptr_swift_drop
        )
    }
    
    public var isNull: Bool {
        self.ptr == nil
    }
    
    public static func wrapped(_ val: AnyObject) -> Self {
        Self(value: val)
    }
    
    public func unowned() -> AnyObject? {
        return self.ptr.unowned()
    }
    
    public func unowned<T: AnyObject>(_ type: T.Type) throws -> T {
        guard let any = self.unowned() else {
            throw CError.nullPtr
        }
        guard let typed = any as? T else {
            throw CError.panic(reason: "Bad type \(T.self)")
        }
        return typed
    }
    
    public mutating func owned() throws -> AnyObject {
        guard let any = self.ptr.owned() else {
            throw CError.nullPtr
        }
        return any
    }
    
    public mutating func owned<T: AnyObject>(_ type: T.Type) throws -> T {
        guard let typed = try self.owned() as? T else {
            throw CError.panic(reason: "Bad type \(T.self)")
        }
        return typed
    }
    
    public mutating func free() throws {
        guard !self.isNull else { throw CError.nullPtr }
        (self.drop)(&self)
    }
}

private func any_ptr_swift_drop(ptr: UnsafeMutablePointer<CAnyDropPtr>!) {
    let _ = ptr.pointee.ptr.owned()!
}

extension CAnyRustPtr: CType {}

extension CAnyRustPtr {
    public mutating func free() {
        tesseract_utils_any_rust_ptr_free(&self);
    }
}
