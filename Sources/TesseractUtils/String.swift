//
//  String.swift
//  
//
//  Created by Yehor Popovych on 22.02.2021.
//

import Foundation
import CTesseractShared

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
    
    public func withRef<T>(_ fn: (Ref) throws -> T) rethrows -> T {
        try withCString(fn)
    }
}

extension String: AsCPtrRef {
    public typealias RefPtr = UnsafePointer<CString>
    
    public func withPtrRef<T>(
        _ fn: (UnsafePointer<CString>) throws -> T
    ) rethrows -> T {
        try withCString {
            var str = CString(_0: $0)
            return try fn(&str)
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
