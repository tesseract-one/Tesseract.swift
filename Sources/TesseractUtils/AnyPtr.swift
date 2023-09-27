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
    
    public func unowned<T>(_ type: T.Type) -> CResult<T> {
        guard let any = self.unowned() else {
            return .failure(.nullPtr)
        }
        guard let typed = any as? T else {
            return .failure(.dynamicCast(reason: "Bad type \(T.self)"))
        }
        return .success(typed)
    }
    
    public mutating func owned() -> CResult<AnyObject> {
        guard let any = self.ptr.owned() else {
            return .failure(.nullPtr)
        }
        return .success(any)
    }
    
    public mutating func owned<T>(_ type: T.Type) -> CResult<T> {
        self.owned().flatMap {
            guard let typed = $0 as? T else {
                return .failure(.dynamicCast(reason: "Bad type \(T.self)"))
            }
            return .success(typed)
        }
    }
    
    public mutating func free() -> CResult<Void> {
        guard !self.isNull else { return .failure(.nullPtr) }
        (self.drop)(&self)
        return .success(())
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
