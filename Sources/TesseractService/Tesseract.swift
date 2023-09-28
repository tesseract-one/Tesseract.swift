//
//  Tesseract.swift
//  
//
//  Created by Yehor Popovych on 26/09/2023.
//

import Foundation
import CTesseractBin
#if !COCOAPODS
@_exported import TesseractServiceTransports
#endif

// Class is not thread safe.
// Use mutex if you need multithreaded setup (but why?)
// Services and transports are thread safe
public final class Tesseract {
    public private(set) var tesseract: ServiceTesseract
    
    public init() {
        tesseract = tesseract_service_new()
    }
    
    public func service<S: Service>(_ service: S) -> Self {
        tesseract = service.asNative().register(in: &tesseract)
        return self
    }
    
    public func transport<T: Transport>(_ transport: T) -> Self {
        tesseract = tesseract_service_add_transport(&tesseract, transport.asNative())
        return self
    }
    
    deinit {
        tesseract_service_free(&tesseract)
    }
}
