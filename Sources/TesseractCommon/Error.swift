//
//  Error.swift
//  
//
//  Created by Yehor Popovych on 18.11.2022.
//

import Foundation
import CTesseractCommon
import TesseractUtils

extension CError {
    public static func emptyRequest(message: String) -> CError {
        CError.error(code: CErrorCodes_EmptyRequest.rawValue, message: message)
    }
    public static func emptyResponse(message: String) -> CError {
        CError.error(code: CErrorCodes_EmptyResponse.rawValue, message: message)
    }
    public static func unsupportedDataType(message: String) -> CError {
        CError.error(code: CErrorCodes_UnsupportedDataType.rawValue, message: message)
    }
    public static func requestExpired(message: String) -> CError {
        CError.error(code: CErrorCodes_RequestExpired.rawValue, message: message)
    }
    public static func wrongProtocolId(message: String) -> CError {
        CError.error(code: CErrorCodes_WrongProtocolId.rawValue, message: message)
    }
    public static func wrongInternalState(message: String) -> CError {
        CError.error(code: CErrorCodes_WrongInternalState.rawValue, message: message)
    }
    public static func serialization(message: String) -> CError {
        CError.error(code: CErrorCodes_Serialization.rawValue, message: message)
    }
    public static func nested(error: Error) -> CError {
        CError.error(code: CErrorCodes_Nested.rawValue, message: error.localizedDescription)
    }
}
