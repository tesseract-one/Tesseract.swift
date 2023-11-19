//
//  TesseractError.swift
//  
//
//  Created by Yehor Popovych on 05/10/2023.
//

import Foundation
import CTesseractShared
#if COCOAPODS
public typealias InteropError = CError
#else
@_exported import TesseractUtils
public typealias InteropError = TesseractUtils.CError
#endif

public protocol TesseractErrorConvertible: CErrorConvertible {
    var tesseract: TesseractError { get }
}

public extension TesseractErrorConvertible {
    @inlinable
    var cError: InteropError { tesseract.cError }
}

public protocol TesseractErrorInitializable: CErrorInitializable {
    init(tesseract: TesseractError)
}

public extension TesseractErrorInitializable {
    init(cError: InteropError) {
        self.init(tesseract: TesseractError(cError: cError))
    }
}

public enum TesseractError: Error {
    case cancelled
    case logger(reason: String)
    case serialization(reason: String)
    case base(error: InteropError)
    case swift(error: NSError)
    case weird(reason: String)
    case custom(code: UInt32, reason: String)
}

extension TesseractError: CustomStringConvertible {
    public var description: String {
        var cstr = cError.withPtrRef {
            tesseract_error_get_description($0)
        }
        return cstr.owned()
    }
}

extension TesseractError: CErrorInitializable {
    public init(cError: InteropError) {
        guard cError.code >= CErrorCode_Sentinel.rawValue else {
            if let swift = cError.swiftError {
                self = .swift(error: swift)
            } else {
                self = .base(error: cError)
            }
            return
        }
        guard cError.code < CTesseractErrorCode_Sentinel.rawValue else {
            self = .custom(code: cError.code - CTesseractErrorCode_Sentinel.rawValue,
                           reason: cError.reason)
            return
        }
        switch CTesseractErrorCode(cError.code) {
        case CTesseractErrorCode_Logger: self = .logger(reason: cError.reason)
        case CTesseractErrorCode_Cancelled: self = .cancelled
        case CTesseractErrorCode_Serialization: self = .serialization(reason: cError.reason)
        case CTesseractErrorCode_Weird: self = .weird(reason: cError.reason)
        default: fatalError("Unknown error code: \(cError.code)")
        }
    }
}

extension TesseractError: CErrorConvertible {
    public var cError: InteropError {
        switch self {
        case .cancelled:
            return InteropError(code: CTesseractErrorCode_Cancelled.rawValue,
                                reason: "")
        case .serialization(reason: let reason):
            return InteropError(code: CTesseractErrorCode_Serialization.rawValue,
                                reason: reason)
        case .weird(reason: let reason):
            return InteropError(code: CTesseractErrorCode_Weird.rawValue,
                                reason: reason)
        case .logger(reason: let reason):
            return InteropError(code: CTesseractErrorCode_Logger.rawValue,
                                reason: reason)
        case .swift(error: let error): return .swift(error: error)
        case .base(error: let error): return error
        case .custom(code: let code, reason: let reason):
            return InteropError(code: CTesseractErrorCode_Sentinel.rawValue + code,
                                reason: reason)
        }
    }
}
