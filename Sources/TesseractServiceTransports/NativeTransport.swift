//
//  NativeTransport.swift
//  TesseractService
//
//  Created by Yehor Popovych on 01.11.2022.
//

import Foundation
import CTesseract
@_exported import TesseractShared

public final class NativeTransportProcessor: TransportProcessor {
    public private(set) var processor: ServiceTransportProcessor
    
    public init(processor: ServiceTransportProcessor) {
        self.processor = processor
    }
    
    deinit {
        tesseract_service_transport_processor_free(&self.processor)
    }
    
    public func process(data: Data) async -> CResult<Data> {
        let future = data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            tesseract_service_transport_processor_process(self.processor,
                                                          ptr.baseAddress,
                                                          UInt(ptr.count))
        }
        return await future.result
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
    public func asNative() -> ServiceTransport {
        ServiceTransport(transport: self)
    }
}

extension BoundTransport {
    public func asNative() -> ServiceBoundTransport {
        ServiceBoundTransport(value: self)
    }
}

private func transport_bind(this: ServiceTransport,
                            processor: ServiceTransportProcessor) -> ServiceBoundTransport
{
    var this = this
    return try! this.owned(Transport.self).get()
        .bind(processor: NativeTransportProcessor(processor: processor))
        .asNative()
}
