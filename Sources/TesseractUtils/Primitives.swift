//
//  Primitives.swift
//
//
//  Created by Yehor Popovych on 18.07.2022.
//

import Foundation
import CTesseractShared

extension Nothing: CType {}

extension Nothing {
    public static let nothing = Nothing(_0: false)
}

extension Int8: CType, CValue {}
extension UInt8: CType, CValue {}
extension Int16: CType, CValue {}
extension UInt16: CType, CValue {}
extension Int32: CType, CValue {}
extension UInt32: CType, CValue {}
extension Int64: CType, CValue {}
extension UInt64: CType, CValue {}
extension Bool: CType, CValue {}

extension UnsafePointer: CPtrRef where Pointee: CPtr {
    public typealias SVal = Pointee.SVal
    
    public func copied() -> Pointee.SVal {
        pointee.copied()
    }
}
