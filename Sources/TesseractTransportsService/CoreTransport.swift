//
//  CoreTransport.swift
//  TesseractService
//
//  Created by Yehor Popovych on 01.11.2022.
//

import Foundation
import CTesseract
#if COCOAPODS
@_exported import TesseractShared
#else
@_exported import TesseractTransportsShared
#endif

public final class CoreTransportProcessor: TransportProcessor {
    public private(set) var processor: ServiceTransportProcessor
    
    public init(processor: ServiceTransportProcessor) {
        self.processor = processor
    }
    
    deinit {
        tesseract_service_transport_processor_free(&self.processor)
    }
    
    public func process(data: Data) async -> Result<Data, TesseractError> {
        let future = data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            tesseract_service_transport_processor_process(self.processor,
                                                          ptr.baseAddress,
                                                          UInt(ptr.count))
        }
        return await future.result.castError()
    }
}

extension ServiceTransport: CSwiftAnyDropPtr {}

extension ServiceTransport {
    public init(transport: Transport) {
        self = ServiceTransport(value: transport)
        self.bind = transport_bind
    }
}

extension Transport {
    public func toCore() -> ServiceTransport {
        ServiceTransport(transport: self)
    }
}

extension BoundTransport {
    public func toCore() -> ServiceBoundTransport {
        ServiceBoundTransport(value: self)
    }
}

private func transport_bind(this: ServiceTransport,
                            processor: ServiceTransportProcessor) -> ServiceBoundTransport
{
    var this = this
    return try! this.owned(Transport.self).get()
        .bind(processor: CoreTransportProcessor(processor: processor))
        .toCore()
}
