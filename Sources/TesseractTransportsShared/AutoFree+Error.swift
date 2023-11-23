//
//  AutoFree+Error.swift
//  
//
//  Created by Yehor Popovych on 23/11/2023.
//

import Foundation
import CTesseractShared
#if !COCOAPODS
import TesseractUtils
#endif

public extension AutoFree {
    convenience init(
        initializer: (UnsafeMutablePointer<Ptr>,
                      UnsafeMutablePointer<CTesseractShared.CError>) -> Bool
    ) throws {
        try self.init(error: TesseractError.self, initializer: initializer)
    }
}
