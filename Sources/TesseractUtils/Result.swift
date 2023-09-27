//
//  Result.swift
//  
//
//  Created by Yehor Popovych on 22.02.2021.
//

import Foundation
import CTesseract

public typealias CResult<T> = Result<T, CError>

// Result is unfinished
public protocol CResultPtr: CType, CPtr where Val == CResult<SResVal> {
    associatedtype CResTag: Equatable
    associatedtype CResVal: CType
    associatedtype SResVal
    
    var tag: CResTag { get set }
    var err: CTesseract.CError { get set }
    var ok: CResVal { get set }
    
    static var ok: CResTag { get }
    static var err: CResTag { get }
}


public extension CResult {
    static func wrap<S: CType>(
        ccall: @escaping (UnsafeMutablePointer<S>, UnsafeMutablePointer<CTesseract.CError>) -> Bool
    ) -> CResult<S> {
        var error = CTesseract.CError()
        var val = S()
        if !ccall(&val, &error) {
            return .failure(error.owned())
        }
        return .success(val)
    }
}

public extension CResult {
    static func wrap<S: CType>(
        ccall: @escaping (UnsafeMutablePointer<S>, UnsafeMutablePointer<CTesseract.CError>) -> COptionResponseResult
    ) -> CResult<S?> {
        var error = CTesseract.CError()
        var val = S()
        switch ccall(&val, &error) {
        case COptionResponseResult_Error: return .failure(error.owned())
        case COptionResponseResult_None: return .success(nil)
        case COptionResponseResult_Some: return .success(val)
        default: fatalError("Unknown enum case!")
        }
    }
}

extension CResult {
    static func wrap(
        ccall: @escaping (UnsafeMutablePointer<CString?>, UnsafeMutablePointer<CTesseract.CError>) -> Bool
    ) -> CResult<CString> {
        var error = CTesseract.CError()
        var val: CString? = nil
        if !ccall(&val, &error) {
            return .failure(error.owned())
        }
        return .success(val!)
    }
}

extension CResult {
    static func wrap(
        ccall: @escaping (UnsafeMutablePointer<CString?>, UnsafeMutablePointer<CTesseract.CError>) -> COptionResponseResult
    ) -> CResult<CString?> {
        var error = CTesseract.CError()
        var val: CString? = nil
        switch ccall(&val, &error) {
        case COptionResponseResult_Error: return .failure(error.owned())
        case COptionResponseResult_None: return .success(nil)
        case COptionResponseResult_Some: return .success(val)
        default: fatalError("Unknown enum case!")
        }
    }
}

public extension CResult {
    static func wrap(
        ccall: @escaping (UnsafeMutablePointer<CTesseract.CError>) -> Bool
    ) -> CResult<Void> {
        var error = CTesseract.CError()
        if !ccall(&error) {
            return .failure(error.owned())
        }
        return .success(())
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
