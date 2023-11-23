//
//  CoreConvertible.swift
//  
//
//  Created by Yehor Popovych on 23/11/2023.
//

import Foundation
#if !COCOAPODS
import TesseractUtils
#endif

public protocol CoreConvertible<Core> {
    associatedtype Core: CType
    
    func toCore() -> Core
}
