//
//  Result.swift
//  
//
//  Created by Yehor Popovych on 22.02.2021.
//

import Foundation
import CTesseractUtils

public typealias CResult<T> = Result<T, CError>

// Result is unfinished
public protocol CResultPtr: CType, CPtr where Val == CResult<SResVal> {
    associatedtype CResTag: Equatable
    associatedtype CResVal: CType
    associatedtype SResVal
    
    var tag: CResTag { get set }
    var err: CTesseractUtils.CError { get set }
    var ok: CResVal { get set }
    
    static var ok: CResTag { get }
    static var err: CResTag { get }
}


public extension CResult {
    static func wrap<S: CType>(
        ccall: @escaping (UnsafeMutablePointer<S>, UnsafeMutablePointer<CTesseractUtils.CError>) -> Bool
    ) -> CResult<S> {
        var error = CTesseractUtils.CError()
        var val = S()
        if !ccall(&val, &error) {
            return .failure(error.owned())
        }
        return .success(val)
    }
}

public extension CResult {
    static func wrap<S: CType>(
        ccall: @escaping (UnsafeMutablePointer<UnsafeMutablePointer<S>?>, UnsafeMutablePointer<CTesseractUtils.CError>) -> Bool
    ) -> CResult<Optional<S>> {
        var error = CTesseractUtils.CError()
        var val = S()
        return withUnsafeMutablePointer(to: &val) { valPtr in
            var option = Optional(valPtr)
            if !ccall(&option, &error) {
                return .failure(error.owned())
            }
            return .success(option?.pointee)
        }
    }
}

//extension CResult {
//    static func wrap(
//        ccall: @escaping (UnsafeMutablePointer<CString?>, UnsafeMutablePointer<CTesseract.CError>) -> Bool
//    ) -> CResult<CString?> {
//        var error = CTesseract.CError()
//        var val: CString? = nil
//        if !ccall(&val, &error) {
//            return .failure(error.owned())
//        }
//        return .success(val)
//    }
//}

public extension CResult {
    static func wrap(
        ccall: @escaping (UnsafeMutablePointer<CTesseractUtils.CError>) -> Bool
    ) -> CResult<Void> {
        var error = CTesseractUtils.CError()
        if !ccall(&error) {
            return .failure(error.owned())
        }
        return .success(())
    }
}
