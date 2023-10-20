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
        self.init(cError: InteropError(parsing: error))
    }
}

extension TesseractError: CustomNSError {
    /// The domain of the error.
    public static var errorDomain: String { "TesseractError" }

    /// The error code within the given domain.
    public var errorCode: Int {
        Int(bitPattern: UInt(cError.code))
    }

    /// The user-info dictionary.
    public var errorUserInfo: [String : Any] {
        cError.errorUserInfo
    }
}
