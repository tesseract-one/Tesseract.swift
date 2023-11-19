//
//  Result.swift
//  
//
//  Created by Yehor Popovych on 22.02.2021.
//

import Foundation
import CTesseractShared

public typealias CResult<T> = Result<T, CError>

// Result is unfinished
public protocol CResultPtr: CType, CPtr where Val == CResult<SResVal> {
    associatedtype CResTag: Equatable
    associatedtype CResVal: CType
    associatedtype SResVal
    
    var tag: CResTag { get set }
    var err: CTesseractShared.CError { get set }
    var ok: CResVal { get set }
    
    static var ok: CResTag { get }
    static var err: CResTag { get }
}

public extension Result {
    static func wrap<S: CType, F: CType & Error>(
        ccall: @escaping (UnsafeMutablePointer<S>, UnsafeMutablePointer<F>) -> Bool
    ) -> Result<S, F> {
        var val = S()
        var error = F()
        if !ccall(&val, &error) { return .failure(error) }
        return .success(val)
    }
}

public extension Result {
    static func wrap<S: CType, F: CType & CPtr>(
        ccall: @escaping (UnsafeMutablePointer<S>, UnsafeMutablePointer<F>) -> Bool
    ) -> Result<S, F.Val> where F.Val: Error {
        var val = S()
        var error = F()
        if !ccall(&val, &error) { return .failure(error.owned()) }
        return .success(val)
    }
}

public extension Result {
    static func wrap<S: CType, F: CType & Error>(
        ccall: @escaping (UnsafeMutablePointer<S>,
                          UnsafeMutablePointer<F>) -> COptionResponseResult
    ) -> Result<S?, F> {
        var val = S()
        var error = F()
        switch ccall(&val, &error) {
        case COptionResponseResult_Error: return .failure(error)
        case COptionResponseResult_None: return .success(nil)
        case COptionResponseResult_Some: return .success(val)
        default: fatalError("Unknown enum case!")
        }
    }
}

public extension Result {
    static func wrap<S: CType, F: CType & CPtr>(
        ccall: @escaping (UnsafeMutablePointer<S>,
                          UnsafeMutablePointer<F>) -> COptionResponseResult
    ) -> Result<S?, F.Val> where F.Val: Error {
        var val = S()
        var error = F()
        switch ccall(&val, &error) {
        case COptionResponseResult_Error: return .failure(error.owned())
        case COptionResponseResult_None: return .success(nil)
        case COptionResponseResult_Some: return .success(val)
        default: fatalError("Unknown enum case!")
        }
    }
}

public extension Result {
    static func wrap<F: CType & Error> (
        ccall: @escaping (UnsafeMutablePointer<F>) -> Bool
    ) -> Result<Void, F> {
        var error = F()
        if !ccall(&error) { return .failure(error) }
        return .success(())
    }
}

public extension Result {
    static func wrap<F: CType & CPtr> (
        ccall: @escaping (UnsafeMutablePointer<F>) -> Bool
    ) -> Result<Void, F.Val> where F.Val: Error {
        var error = F()
        if !ccall(&error) { return .failure(error.owned()) }
        return .success(())
    }
}

public extension Result where Failure == CError {
    func castError<E: CErrorInitializable>() -> Result<Success, E> {
        mapError { E(cError: $0) }
    }
    
    func castError<E: CErrorInitializable>(_: E.Type) -> Result<Success, E> {
        castError()
    }
}

public extension Result where Failure: CErrorConvertible {
    func castError() -> Result<Success, CError> {
        mapError { $0.cError }
    }
}

public extension Result {
    func asyncFlatMap<NewSuccess>(
        _ transform: (Success) async -> Result<NewSuccess, Failure>
    ) async -> Result<NewSuccess, Failure> {
        switch self {
        case .failure(let err): return .failure(err)
        case .success(let val): return await transform(val)
        }
    }
}
