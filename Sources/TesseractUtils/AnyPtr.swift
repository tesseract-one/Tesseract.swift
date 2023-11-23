//
//  AnyPtr.swift
//  
//
//  Created by Yehor Popovych on 16.12.2022.
//

import Foundation
import CTesseractShared

extension CAnyRustPtr: CType, CFree {
    public mutating func free() {
        tesseract_utils_any_rust_ptr_free(&self)
    }
}

extension CAnyDropPtr: CType, CFree {
    public mutating func free() {
        (self.drop)(&self)
    }
}

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
    
    public func unowned<T>(_ t: T.Type) -> CResult<T> {
        guard let any = self.unowned() else {
            return .failure(.null(Self.self))
        }
        guard let typed = any as? T else {
            return .failure(.cast(from: Self.self, to: t))
        }
        return .success(typed)
    }
    
    public mutating func owned() -> CResult<AnyObject> {
        guard let any = self.ptr.owned() else {
            return .failure(.null(Self.self))
        }
        return .success(any)
    }
    
    public mutating func owned<T>(_ t: T.Type) -> CResult<T> {
        self.owned().flatMap {
            guard let typed = $0 as? T else {
                return .failure(.cast(from: Self.self, to: t))
            }
            return .success(typed)
        }
    }
}

private func any_ptr_swift_drop(ptr: UnsafeMutablePointer<CAnyDropPtr>!) {
    let _ = ptr.pointee.ptr.owned()!
}
