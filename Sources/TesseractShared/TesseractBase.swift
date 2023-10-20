//
//  File.swift
//  
//
//  Created by Yehor Popovych on 06/10/2023.
//

import Foundation
import CTesseractBin
#if !COCOAPODS
@_exported import TesseractTransportsShared
@_exported import TesseractUtils
#endif

open class TesseractBase {
    public init() throws {
        let _ = try Self.initialize.get()
    }
    
#if DEBUG
    public static var logLevel: TesseractShared.LogLevel = .debug
#else
    public static var logLevel: TesseractShared.LogLevel = .warn
#endif
    
    // One time call
    static var initialize: TResult<()> = {
        CResult<Void>.wrap { error in
            tesseract_sdk_init(TesseractBase.logLevel.cLevel, error)
        }.castError()
    }()
}
