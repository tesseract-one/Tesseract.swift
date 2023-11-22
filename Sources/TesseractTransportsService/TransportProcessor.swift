//
//  CoreTransportProcessor.swift
//  
//
//  Created by Yehor Popovych on 22/11/2023.
//

import Foundation
import CTesseractShared
#if COCOAPODS
@_exported import TesseractShared
#else
@_exported import TesseractTransportsShared
#endif

public final class TransportProcessor {
    public private(set) var processor: ServiceTransportProcessor
    
    public init(processor: ServiceTransportProcessor) {
        self.processor = processor
    }
    
    deinit {
        tesseract_service_transport_processor_free(&self.processor)
    }
    
    public func process(data: Data) async -> Result<Data, TesseractError> {
        let future = data.withPtrRef {
            tesseract_service_transport_processor_process(processor, $0)
        }
        return await future.result.castError()
    }
}
