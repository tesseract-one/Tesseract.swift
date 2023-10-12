//
//  TesseractError+Ext.swift
//  
//
//  Created by Yehor Popovych on 05/10/2023.
//

import Foundation
import CTesseract
#if !COCOAPODS
import TesseractUtils
#endif

public typealias TResult<V> = Result<V, TesseractError>

public extension CFuturePtr {
    init<E: TesseractErrorConvertible>(_ cb: @escaping @Sendable () async -> Result<Val, E>) {
        self.init { await cb().mapError { $0.tesseract.cError } }
    }
}

public extension Result where Failure: TesseractErrorConvertible {
    func castError() -> Result<Success, TesseractError> {
        mapError { $0.tesseract }
    }
}

public extension Result where Failure == TesseractError {
    func castError<E: TesseractErrorInitializable>() -> Result<Success, E> {
        mapError { E(tesseract: $0) }
    }
    
    func castError<E: TesseractErrorInitializable>(_: E.Type) -> Result<Success, E> {
        castError()
    }
}

public extension TesseractError {
    init(parsing error: NSError) {
        // We have simple swift error. Doesn't have any markers
        guard error.userInfo[InteropError.NSErrorMarker] != nil &&
                error.userInfo[Self.NSErrorMarker] != nil else
        {
            self = .swift(error: error)
            return
        }
        // Doesn't have our marker.
        // Seems as CError converted to NSError.
        // Asking CError to parse
        guard error.userInfo[Self.NSErrorMarker] != nil else {
            self.init(cError: InteropError.swift(error: error))
            return
        }
        // Ok. Seems as TesseractError
        // Try convert code
        guard let code = UInt32(exactly: UInt(bitPattern: error.code)) else {
            self = .weird(reason: error.localizedDescription)
            return
        }
        switch code {
        case CErrorCode_Null.rawValue: self = .null(reason: error.localizedDescription)
        case CErrorCode_Panic.rawValue: self = .panic(reason: error.localizedDescription)
        case CErrorCode_Utf8.rawValue: self = .utf8(reason: error.localizedDescription)
        case CErrorCode_Cast.rawValue: self = .cast(reason: error.localizedDescription)
        case CTesseractErrorCode_Cancelled.rawValue: self = .cancelled
        case CTesseractErrorCode_Serialization.rawValue:
            self = .serialization(reason: error.localizedDescription)
        case CTesseractErrorCode_Weird.rawValue: self = .weird(reason: error.localizedDescription)
        case CErrorCode_Swift.rawValue:
            guard let error = error.userInfo[NSUnderlyingErrorKey] as? NSError else {
                self = .weird(reason: error.localizedDescription)
                return
            }
            self = .swift(error: error)
        case let code where code >= CTesseractErrorCode_Sentinel.rawValue:
            self = .custom(code: code - CTesseractErrorCode_Sentinel.rawValue,
                           reason: error.localizedDescription)
        default: self = .weird(reason: error.localizedDescription)
        }
    }
}

extension TesseractError: CustomNSError {
    /// The domain of the error.
    public static var errorDomain: String { "TesseractError" }

    /// The error code within the given domain.
    public var errorCode: Int {
        var code: UInt
        switch self {
        case .cancelled: code = UInt(CTesseractErrorCode_Cancelled.rawValue)
        case .null: code = UInt(CErrorCode_Null.rawValue)
        case .panic: code = UInt(CErrorCode_Panic.rawValue)
        case .logger: code = UInt(CErrorCode_Logger.rawValue)
        case .utf8: code = UInt(CErrorCode_Utf8.rawValue)
        case .cast: code = UInt(CErrorCode_Cast.rawValue)
        case .swift: code = UInt(CErrorCode_Swift.rawValue)
        case .serialization: code = UInt(CTesseractErrorCode_Serialization.rawValue)
        case .weird: code = UInt(CTesseractErrorCode_Weird.rawValue)
        case .custom(code: let c, _): code = UInt(c + CTesseractErrorCode_Sentinel.rawValue)
        }
        return Int(bitPattern: code)
    }

    /// The user-info dictionary.
    public var errorUserInfo: [String : Any] {
        switch self {
        case .custom(code: _, reason: let reason), .weird(reason: let reason),
                .null(reason: let reason), .panic(reason: let reason),
                .logger(reason: let reason), .utf8(reason: let reason),
                .cast(reason: let reason), .serialization(reason: let reason):
            return [InteropError.NSErrorMarker: true,
                     NSLocalizedDescriptionKey: reason,
                           Self.NSErrorMarker: true]
        case .swift(error: let err):
            let cerr = InteropError.swift(error: err)
            return [InteropError.NSErrorMarker: true,
                     NSLocalizedDescriptionKey: cerr.reason,
                          NSUnderlyingErrorKey: err,
                            Self.NSErrorMarker: true]
        case .cancelled:
            return [InteropError.NSErrorMarker: true,
                     NSLocalizedDescriptionKey: "Cancelled",
                            Self.NSErrorMarker: true]
        }
    }
    
    public static let NSErrorMarker = "__Tesseract.TesseractError__"
}
