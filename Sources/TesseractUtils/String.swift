//
//  String.swift
//  
//
//  Created by Yehor Popovych on 22.02.2021.
//

import Foundation
import CTesseract

public extension CStringRef {
    func copied() -> String {
        String(cString: self)
    }
}
extension CString: CType {}

extension CString: CPtr {
    public typealias Val = String
    
    public func copied() -> Val {
        String(cString: self._0)
    }
    
    public mutating func owned() -> String {
        defer { self.free() }
        return self.copied()
    }
    
    public mutating func free() {
        tesseract_utils_cstring_free(self)
    }
}

extension String: AsCRef {
    public typealias Ref = CStringRef
    
    public func withRef<T>(_ fn: @escaping (Ref) throws -> T) rethrows -> T {
        try withCString(fn)
    }
}

extension String: AsCPtrRef {
    public typealias RefPtr = UnsafePointer<CString>
    
    public func withPtrRef<T>(
        _ fn: @escaping (UnsafePointer<CString>) throws -> T
    ) rethrows -> T {
        try withCString {
            try withUnsafePointer(to: CString(_0: $0)) { try fn($0) }
        }
    }
}

extension String: AsCPtrCopy {
    public func copiedPtr() -> CString {
        try! withRef { cstr in
            try CResult<CString>.wrap { res, err in
                tesseract_utils_cstring_new(cstr, res, err)
            }.get()
        }
    }
}
