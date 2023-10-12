//
//  LogLevel.swift
//  
//
//  Created by Yehor Popovych on 06/10/2023.
//

import Foundation
import CTesseract

public enum LogLevel: UInt8, CaseIterable {
    case off = 0
    case error
    case warn
    case info
    case debug
    case trace
    
    public var cLevel: CTesseract.LogLevel {
        CTesseract.LogLevel(rawValue: UInt32(self.rawValue))
    }
}
