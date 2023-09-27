//
//  ErrorCodes.swift
//  
//
//  Created by Yehor Popovych on 18.11.2022.
//

import Foundation
import CTesseract
#if COCOAPODS
public typealias UtilsError = CError
#else
@_exported import TesseractUtils
public typealias UtilsError = TesseractUtils.CError
#endif

extension UtilsError {
    @inlinable
    public static func emptyRequest(message: String) -> Self {
        .error(code: CErrorCodes_EmptyRequest.rawValue, message: message)
    }
    
    @inlinable
    public static func emptyResponse(message: String) -> Self {
        .error(code: CErrorCodes_EmptyResponse.rawValue, message: message)
    }
    
    @inlinable
    public static func unsupportedDataType(message: String) -> Self {
        .error(code: CErrorCodes_UnsupportedDataType.rawValue, message: message)
    }
    
    @inlinable
    public static func requestExpired(message: String) -> Self {
        .error(code: CErrorCodes_RequestExpired.rawValue, message: message)
    }
    
    @inlinable
    public static func wrongProtocolId(message: String) -> Self {
        .error(code: CErrorCodes_WrongProtocolId.rawValue, message: message)
    }
    
    @inlinable
    public static func wrongInternalState(message: String) -> Self {
        .error(code: CErrorCodes_WrongInternalState.rawValue, message: message)
    }
    
    @inlinable
    public static func serialization(message: String) -> Self {
        .error(code: CErrorCodes_Serialization.rawValue, message: message)
    }
    
    @inlinable
    public static func nested(error: Error) -> Self {
        .error(code: CErrorCodes_Nested.rawValue, message: error.localizedDescription)
    }
}
