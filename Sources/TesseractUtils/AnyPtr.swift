//
//  RPtr.swift
//
//
//  Created by Yehor Popovych on 21.07.2022.
//

import Foundation
import CTesseractUtils

public protocol FromAnyPtr {
    init(anyptr: inout CAnyPtr)
}

public protocol AsAnyPtrCopy {
    func copiedAnyPtr() -> CAnyPtr
}

public protocol AsAnyPtrOwn {
    mutating func ownedAnyPtr() -> CAnyPtr
}

extension CAnyPtr {
    public init<T: AsAnyPtrCopy>(copying val: T) {
        self = val.copiedAnyPtr()
    }
    
    public init<T: AsAnyPtrOwn>(owning val: inout T) {
        self = val.ownedAnyPtr()
    }
    
    public mutating func owned<T: FromAnyPtr>(_ type: T.Type) -> T {
        type.init(anyptr: &self)
    }
    
    public mutating func free() {
        tesseract_utils_anyptr_free(self);
    }
}

// Container Extensions

