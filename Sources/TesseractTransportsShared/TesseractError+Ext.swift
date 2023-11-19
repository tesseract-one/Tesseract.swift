//
//  TesseractError+Ext.swift
//  
//
//  Created by Yehor Popovych on 05/10/2023.
//

import Foundation
import CTesseractShared
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
    init(tesseract fn: () async throws -> Success) async {
        do {
            self = await .success(try fn())
        } catch let err as TesseractErrorConvertible {
            self = .failure(err.tesseract)
        } catch let err as CErrorConvertible {
            self = .failure(TesseractError(cError: err.cError))
        } catch {
            self = .failure(TesseractError(parsing: error as NSError))
        }
    }
    
    func castError<E: TesseractErrorInitializable>() -> Result<Success, E> {
        mapError { E(tesseract: $0) }
    }
    
    func castError<E: TesseractErrorInitializable>(_: E.Type) -> Result<Success, E> {
        castError()
    }
}

public extension TesseractError {
    @inlinable init(parsing error: NSError) {
        self.init(cError: .init(parsing: error))
    }
    
    @inlinable static func null<T>(_ type: T.Type) -> Self {
        .init(cError: .null(type))
    }
    
    @inlinable static func panic(reason: String) -> Self {
        .init(cError: .panic(reason: reason))
    }
    
    @inlinable static func cast<F, T>(from: F.Type, to: T.Type) -> Self {
        .init(cError: .cast(from: from, to: to))
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
