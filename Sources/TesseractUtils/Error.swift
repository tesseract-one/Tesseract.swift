//
//  Error.swift
//  
//
//  Created by Yehor Popovych on 22.02.2021.
//

import Foundation
import CTesseract

public enum CError: Error {
    case nullPtr
    case canceled
    case panic(reason: String)
    case utf8(message: String)
    case dynamicCast(reason: String)
    case error(code: UInt32, message: String)
    
    public init(copying error: CTesseract.CError) {
        switch error.tag {
        case CError_NullPtr: self = .nullPtr
        case CError_Canceled: self = .canceled
        case CError_Panic: self = .panic(reason: error.panic.copied())
        case CError_Utf8Error: self = .utf8(message: error.utf8_error.copied())
        case CError_ErrorCode:
            self = .error(code: error.error_code._0,
                          message: error.error_code._1.copied())
        case CError_DynamicCast:
            self = .dynamicCast(reason: error.dynamic_cast_.copied())
        default: fatalError("Unknown enum tag: \(error.tag)")
        }
    }
}

extension CError: AsCPtrCopy {
    public typealias CopyPtr = CTesseract.CError
    
    public func copiedPtr() -> CopyPtr {
        var error = CTesseract.CError()
        switch self {
        case .nullPtr: error.tag = CError_NullPtr
        case .canceled: error.tag = CError_Canceled
        case .error(code: let code, message: let message):
            error.tag = CError_ErrorCode
            error.error_code._0 = code
            error.error_code._1 = message.copiedPtr()
        case .panic(reason: let panic):
            error.tag = CError_Panic
            error.panic = panic.copiedPtr()
        case .utf8(message: let message):
            error.tag = CError_Utf8Error
            error.utf8_error = message.copiedPtr()
        case .dynamicCast(reason: let reason):
            error.tag = CError_DynamicCast
            error.dynamic_cast_ = reason.copiedPtr()
        }
        return error
    }
}

extension CError: AsCPtrRef {
    public typealias RefPtr = CTesseract.CError
    
    public func withPtrRef<T>(_ fn: @escaping (RefPtr) throws -> T) rethrows -> T {
        var error = CTesseract.CError()
        switch self {
        case .nullPtr:
            error.tag = CError_NullPtr
            return try fn(error)
        case .canceled:
            error.tag = CError_Canceled
            return try fn(error)
        case .error(code: let code, message: let message):
            error.tag = CError_ErrorCode
            error.error_code._0 = code
            return try message.withRef {
                error.error_code._1 = $0
                return try fn(error)
            }
        case .panic(reason: let reason):
            error.tag = CError_Panic
            return try reason.withRef {
                error.panic = $0
                return try fn(error)
            }
        case .utf8(message: let message):
            error.tag = CError_Utf8Error
            return try message.withRef {
                error.utf8_error = $0
                return try fn(error)
            }
        case .dynamicCast(reason: let reason):
            error.tag = CError_Utf8Error
            return try reason.withRef {
                error.dynamic_cast_ = $0
                return try fn(error)
            }
        }
    }
}

extension CTesseract.CError: CType {}

extension CTesseract.CError: CPtr {
    public typealias Val = CError
    
    public func copied() -> CError {
        CError(copying: self)
    }
    
    public mutating func owned() -> CError {
        defer { self.free() }
        return self.copied()
    }
    
    public mutating func free() {
        tesseract_utils_error_free(&self)
        self.tag = CError_Tag(UInt32.max)
    }
}
