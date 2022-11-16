//
//  String.swift
//  
//
//  Created by Yehor Popovych on 22.02.2021.
//

import Foundation
import CTesseractUtils

extension CString: CPtr {
    public typealias Val = String
    
    public func copied() -> Val {
        String(cString: self)
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

extension String: AsCPtrCopy {
    public func copiedPtr() -> CString {
        try! withRef { cstr in
            try CResult<CString?>.wrap { res, err in
                tesseract_utils_cstring_new(cstr, res, err)
            }.get()
        }!
    }
}
