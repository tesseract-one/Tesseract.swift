//
//  Error.swift
//  
//
//  Created by Yehor Popovych on 22.02.2021.
//

import Foundation
import CTesseractShared

public protocol CErrorConvertible: Error {
    var cError: CError { get }
}

public protocol CErrorInitializable: Error {
    init(cError: CError)
}

public struct CError: Error {
    public let code: UInt32
    public let reason: String
    
    public init(code: UInt32, reason: String) {
        self.code = code
        self.reason = reason
    }
    
    public init(copying error: CTesseractShared.CError) {
        self.code = error.code
        self.reason = error.reason.copied()
    }
    
    public init(parsing error: NSError) {
        guard error.userInfo[Self.NSErrorMarker] != nil else {
            var error = CTesseractShared.CError(error: error)
            self = error.owned()
            return
        }
        guard let code = UInt32(exactly: UInt(bitPattern: error.code)) else {
            var error = CTesseractShared.CError(error: error)
            self = error.owned()
            return
        }
        self.init(code: code, reason: error.localizedDescription)
    }
}

public extension CError {
    static func null<T>(_ type: T.Type) -> Self {
        CError(code: CErrorCode_Null.rawValue, reason: String(describing: type))
    }
    
    static func panic(reason: String) -> Self {
        CError(code: CErrorCode_Panic.rawValue, reason: reason)
    }
    
    static func cast<F, T>(from: F.Type, to: T.Type) -> Self {
        CError(code: CErrorCode_Cast.rawValue, reason: "Can't cast \(from) into \(to)")
    }
    
    static func swift(error: Error) -> Self {
        Self(parsing: error as NSError)
    }
    
    var swiftError: NSError? {
        withPtrRef { $0.swiftError }.map { err in
            var err = err
            return err.owned()
        }
    }
}

extension CError: CustomStringConvertible {
    public var description: String {
        withPtrRef { $0.pointee.description }
    }
}

extension CError: AsCPtrCopy {
    public typealias CopyPtr = CTesseractShared.CError
    
    public func copiedPtr() -> CopyPtr {
        CTesseractShared.CError(code: code, reason: reason.copiedPtr())
    }
}

extension CError: AsCPtrRef {
    public typealias RefPtr = UnsafePointer<CTesseractShared.CError>
    
    public func withPtrRef<T>(_ fn: (RefPtr) throws -> T) rethrows -> T {
        try reason.withPtrRef { reason in
            var error = CTesseractShared.CError(code: code, reason: reason.pointee)
            return try fn(&error)
        }
    }
}

extension NSError {
    public convenience init(copying error: CTesseractShared.SwiftError) {
        self.init(domain: error.domain.copied(), code: error.code,
                  userInfo: [NSLocalizedDescriptionKey: error.description.copied()])
    }
}

extension CTesseractShared.CError: CType, CustomStringConvertible {
    public init(error: NSError) {
        self = tesseract_utils_cerr_new_swift_error(error.code,
                                                    error.domain,
                                                    error.localizedDescription)
    }
    
    public var description: String {
        withUnsafePointer(to: self) { $0.description }
    }
    
    public var swiftError: CTesseractShared.SwiftError? {
        withUnsafePointer(to: self) { $0.swiftError }
    }
}

extension UnsafePointer<CTesseractShared.CError> {
    public var description: String {
        var desc = tesseract_utils_cerr_get_description(self)
        return desc.owned()
    }
    
    public var swiftError: CTesseractShared.SwiftError? {
        guard self.pointee.code == CErrorCode_Swift.rawValue else { return nil }
        return tesseract_utils_cerr_get_swift_error(self)
    }
}

extension CTesseractShared.CError: CPtr {
    public typealias Val = CError
    
    public func copied() -> CError {
        CError(copying: self)
    }
    
    public mutating func owned() -> CError {
        defer { self.free() }
        return self.copied()
    }
    
    public mutating func free() {
        tesseract_utils_cerror_free(&self)
        self.code = UInt32.max
    }
}

extension CTesseractShared.SwiftError: CType {
    public init(error: NSError) {
        self = tesseract_utils_swift_error_new(error.code,
                                               error.domain,
                                               error.localizedDescription)
    }
}
extension CTesseractShared.SwiftError: CPtr {
    public typealias Val = NSError
    
    public func copied() -> NSError {
        NSError(copying: self)
    }
    
    public mutating func owned() -> NSError {
        defer { self.free() }
        return self.copied()
    }
    
    public mutating func free() {
        tesseract_utils_swift_error_free(&self)
    }
}

extension NSError: AsCPtrRef {
    public typealias RefPtr = UnsafePointer<CTesseractShared.SwiftError>
    
    public func withPtrRef<T>(
        _ fn: (UnsafePointer<SwiftError>) throws -> T
    ) rethrows -> T {
        try domain.withPtrRef { domain in
            try self.localizedDescription.withPtrRef { description in
                try withUnsafePointer(
                    to: CTesseractShared.SwiftError(code: self.code,
                                                    domain: domain.pointee,
                                                    description: description.pointee)
                ) { try fn($0) }
            }
        }
    }
}

extension NSError: AsCPtrCopy {
    public typealias CopyPtr = CTesseractShared.SwiftError
    
    public func copiedPtr() -> CTesseractShared.SwiftError {
        CTesseractShared.SwiftError(error: self)
    }
}

extension NSError: CErrorConvertible {
    public var cError: CError { .swift(error: self) }
}

extension CError: CustomNSError {
    /// The domain of the error.
    public static var errorDomain: String { "CError" }

    /// The error code within the given domain.
    public var errorCode: Int { Int(bitPattern: UInt(self.code)) }

    /// The user-info dictionary.
    public var errorUserInfo: [String : Any] {
        if let err = swiftError {
            return [NSLocalizedDescriptionKey: reason,
                         NSUnderlyingErrorKey: err,
                           Self.NSErrorMarker: true]
        } else {
            return [NSLocalizedDescriptionKey: reason,
                           Self.NSErrorMarker: true]
        }
    }
    
    public static let NSErrorMarker = "__Tesseract.CError__"
}
