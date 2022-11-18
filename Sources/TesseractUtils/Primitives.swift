//
//  Primitives.swift
//
//
//  Created by Yehor Popovych on 18.07.2022.
//

import Foundation
import CTesseractUtils

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
