//
//  Tesseract.swift
//  
//
//  Created by Yehor Popovych on 26/09/2023.
//

import Foundation
import CTesseract
#if !COCOAPODS
@_exported import TesseractServiceTransports
#endif

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
