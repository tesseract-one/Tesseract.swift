//
//  TesseractError.swift
//  
//
//  Created by Yehor Popovych on 05/10/2023.
//

import Foundation
import CTesseract
#if COCOAPODS
public typealias InteropError = CError
#else
@_exported import TesseractUtils
public typealias InteropError = TesseractUtils.CError
#endif

public protocol TesseractErrorConvertible {
    var tesseract: TesseractError { get }
}

public protocol TesseractErrorInitializable {
    init(tesseract: TesseractError)
}

public enum TesseractError: Error {
    case cancelled
    case null(reason: String)
    case panic(reason: String)
    case logger(reason: String)
    case utf8(reason: String)
    case cast(reason: String)
    case swift(error: NSError)
    case serialization(reason: String)
    case weird(reason: String)
    case custom(code: UInt32, reason: String)
}

public extension TesseractError {
    init(copying error: CTesseractError) {
        switch error.tag {
        case CTesseractError_Null: self = .null(reason: error.null.copied())
        case CTesseractError_Panic: self = .panic(reason: error.panic.copied())
        case CTesseractError_Logger: self = .logger(reason: error.logger.copied())
        case CTesseractError_Utf8: self = .utf8(reason: error.utf8.copied())
        case CTesseractError_Cast: self = .cast(reason: error.cast.copied())
        case CTesseractError_Serialization:
            self = .serialization(reason: error.serialization.copied())
        case CTesseractError_Weird: self = .weird(reason: error.weird.copied())
        case CTesseractError_Custom:
            self = .custom(code: error.custom._0,
                           reason: error.custom._1.copied())
        case CTesseractError_Cancelled: self = .cancelled
        case CTesseractError_Swift: self = .swift(error: error.swift.copied())
        default: fatalError("unknown error tag: \(error.tag)")
        }
    }
    
    static func null<T>(_ type: T.Type) -> Self {
        .null(reason: String(describing: type))
    }
    
    static func cast<F, T>(from: F.Type, to: T.Type) -> Self {
        .cast(reason: "Can't cast \(from) into \(to)")
    }
    
    static func convert(_ error: Error) -> Self {
        Self(parsing: error as NSError)
    }
}

extension TesseractError: CustomStringConvertible {
    public var description: String {
        withPtrRef { $0.pointee.description }
    }
}

extension TesseractError: CErrorConvertible {
    public var cError: InteropError {
        var err = copiedPtr()
        var cerr = err.cError()
        return cerr.owned()
    }
}

extension TesseractError: CErrorInitializable {
    public init(cError: InteropError) {
        var cerr = cError.copiedPtr()
        var err = CTesseractError(error: &cerr)
        self = err.owned()
    }
}

extension TesseractError: AsCPtrCopy {
    public typealias CopyPtr = CTesseractError
    
    public func copiedPtr() -> CopyPtr {
        var error = CTesseractError()
        switch self {
        case .cancelled: error.tag = CTesseractError_Cancelled
        case .null(reason: let reason):
            error.tag = CTesseractError_Null
            error.null = reason.copiedPtr()
        case .panic(reason: let reason):
            error.tag = CTesseractError_Panic
            error.panic = reason.copiedPtr()
        case .logger(reason: let reason):
            error.tag = CTesseractError_Logger
            error.logger = reason.copiedPtr()
        case .utf8(reason: let reason):
            error.tag = CTesseractError_Utf8
            error.utf8 = reason.copiedPtr()
        case .cast(reason: let reason):
            error.tag = CTesseractError_Cast
            error.cast = reason.copiedPtr()
        case .swift(error: let err):
            error.tag = CTesseractError_Swift
            error.swift = err.copiedPtr()
        case .serialization(reason: let reason):
            error.tag = CTesseractError_Serialization
            error.serialization = reason.copiedPtr()
        case .weird(reason: let reason):
            error.tag = CTesseractError_Weird
            error.weird = reason.copiedPtr()
        case .custom(code: let code, reason: let reason):
            error.tag = CTesseractError_Custom
            error.custom._0 = code
            error.custom._1 = reason.copiedPtr()
        }
        return error
    }
}

extension TesseractError: AsCPtrRef {
    public typealias RefPtr = UnsafePointer<CTesseractError>

    public func withPtrRef<T>(
        _ fn: @escaping (UnsafePointer<CTesseractError>) throws -> T
    ) rethrows -> T {
        var error = CTesseractError()
        switch self {
        case .cancelled:
            error.tag = CTesseractError_Cancelled
            return try fn(&error)
        case .null(reason: let reason):
            return try reason.withPtrRef {
                error.tag = CTesseractError_Null
                error.null = $0.pointee
                return try fn(&error)
            }
        case .panic(reason: let reason):
            return try reason.withPtrRef {
                error.tag = CTesseractError_Panic
                error.panic = $0.pointee
                return try fn(&error)
            }
        case .logger(reason: let reason):
            return try reason.withPtrRef {
                error.tag = CTesseractError_Logger
                error.panic = $0.pointee
                return try fn(&error)
            }
        case .utf8(reason: let reason):
            return try reason.withPtrRef {
                error.tag = CTesseractError_Utf8
                error.utf8 = $0.pointee
                return try fn(&error)
            }
        case .cast(reason: let reason):
            return try reason.withPtrRef {
                error.tag = CTesseractError_Cast
                error.cast = $0.pointee
                return try fn(&error)
            }
        case .swift(error: let err):
            return try err.withPtrRef {
                error.tag = CTesseractError_Swift
                error.swift = $0.pointee
                return try fn(&error)
            }
        case .serialization(reason: let reason):
            return try reason.withPtrRef {
                error.tag = CTesseractError_Serialization
                error.serialization = $0.pointee
                return try fn(&error)
            }
        case .weird(reason: let reason):
            return try reason.withPtrRef {
                error.tag = CTesseractError_Weird
                error.weird = $0.pointee
                return try fn(&error)
            }
        case .custom(code: let code, reason: let reason):
            return try reason.withPtrRef {
                error.tag = CTesseractError_Custom
                error.custom._0 = code
                error.custom._1 = $0.pointee
                return try fn(&error)
            }
        }
    }
}

public extension UnsafePointer<CTesseractError> {
    var description: String {
        var desc = tesseract_error_get_description(self)
        return desc.owned()
    }
}

extension CTesseractError: CType, CustomStringConvertible {
    public init(error: inout CTesseract.CError) {
        self = tesseract_error_from_cerror(&error)
    }
    
    public var description: String {
        withUnsafePointer(to: self) { $0.description }
    }
    
    mutating func cError() -> CTesseract.CError {
        tesseract_error_to_cerror(&self)
    }
}

extension CTesseractError: CPtr {
    public typealias Val = TesseractError
    
    public func copied() -> TesseractError {
        TesseractError(copying: self)
    }
    
    public mutating func owned() -> TesseractError {
        defer { self.free() }
        return self.copied()
    }
    
    public mutating func free() {
        tesseract_error_free(&self)
    }
}
