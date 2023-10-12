//
//  Tesseract.swift
//  
//
//  Created by Yehor Popovych on 26/09/2023.
//

import Foundation
import CTesseractBin
#if !COCOAPODS
@_exported import TesseractTransportsService
#endif
@_exported import TesseractShared

// Class is not thread safe.
// Use mutex if you need multithreaded setup (but why?)
// Services and transports are thread safe
public final class Tesseract: TesseractBase {
    public private(set) var tesseract: ServiceTesseract!
    
    public override init() throws {
        try super.init()
        tesseract = tesseract_service_new()
    }
    
    public func service<S: Service>(_ service: S) -> Self {
        tesseract = service.toCore().register(in: &tesseract)
        return self
    }
    
    public func transport<T: Transport>(_ transport: T) -> Self {
        tesseract = tesseract_service_add_transport(&tesseract, transport.toCore())
        return self
    }
    
    deinit {
        tesseract_service_free(&tesseract)
        tesseract = nil
    }
}
